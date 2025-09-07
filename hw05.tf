# Роли сервисного аккаунта
# iam.serviceAccounts.accessKeyAdmin - чтобы создавать S3-ключи
# storage.admin — чтобы создавать бакеты в облачном хранилище
# vpc.privateAdmin - чтобы создавать VPC
# vpc.securityGroups.admin - чтобы создавать security groups
# mdb.admin — чтобы создавать кластеры Managed Service for PostgreSQL


locals {
  # Достаём id сервисного аккаунта из JSON-ключа, который уже используете в providers.tf
  sa_id = jsondecode(file(var.sa_key_file)).service_account_id
}

# Создаём статический S3-ключ для этого сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_s3" {
  service_account_id = local.sa_id
  description        = "Static S3 key for TF HW05"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${local.sa_id}"
}


# Создаём бакет в облачном хранилище
resource "yandex_storage_bucket" "test_bucket" {
  bucket        = var.bucket_name
  access_key    = yandex_iam_service_account_static_access_key.sa_s3.access_key
  secret_key    = yandex_iam_service_account_static_access_key.sa_s3.secret_key
  folder_id     = var.folder_id
  force_destroy = true
}



############################
# VPC + Subnet + SecGroup  #
############################
resource "yandex_vpc_network" "net" {
  name = "pg-net"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "pg-subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "pg" {
  name        = "pg-sg"
  network_id  = yandex_vpc_network.net.id
  description = "Allow 6432/5432 from my_ip; any egress"

  # исходящий — любой
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Any egress"
  }

  # вход на пулер 6432 (рекомендованный порт подключения к кластеру)
  ingress {
    protocol       = "TCP"
    port           = 6432
    v4_cidr_blocks = var.my_ip != "" ? [var.my_ip] : ["0.0.0.0/0"]
    description    = "PostgreSQL (pooler) 6432"
  }

  # (опционально) прямой вход на 5432
  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = var.my_ip != "" ? [var.my_ip] : ["0.0.0.0/0"]
    description    = "PostgreSQL direct 5432"
  }
}

########################################
# Managed PostgreSQL cluster (1 host)  #
########################################
resource "yandex_mdb_postgresql_cluster" "pg" {
  name        = var.cluster_name
  description = var.cluster_description
  labels = {
    project = "otus-hw05"
  }
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.net.id
  security_group_ids  = [yandex_vpc_security_group.pg.id]
  deletion_protection = false

  config {
    version = var.pg_version

    resources {
      resource_preset_id = var.pg_preset
      disk_type_id       = var.disk_type
      disk_size          = var.db_disk_gb
    }
  }

  host {
    zone = var.zone
    # ...other host settings...
  }
}

#####################
# DB user & database
#####################
resource "yandex_mdb_postgresql_user" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.pg.id
  name       = var.db_user
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.pg.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.app.name
}

################
# Handy outputs
################
output "pg_host_fqdn" {
  value = yandex_mdb_postgresql_cluster.pg.host[0].fqdn
}

output "psql_conn_string_pooler" {
  sensitive = true
  value     = "host=${yandex_mdb_postgresql_cluster.pg.host[0].fqdn} port=6432 dbname=${yandex_mdb_postgresql_database.app.name} user=${yandex_mdb_postgresql_user.app.name} password=${var.db_password} sslmode=verify-full"
}
