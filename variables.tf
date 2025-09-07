# Идентификаторы облака и каталога
variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

# Зона по умолчанию (лучше ru-central1-a или ru-central1-b)
variable "zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

# Путь к ключу сервисного аккаунта
variable "sa_key_file" {
  description = "Path to service account key JSON file"
  type        = string
}

# Путь к вашему публичному SSH-ключу
variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_ip" {
  description = "Your external IP in CIDR (e.g., 203.0.113.5/32). Empty string means 'open to all' in examples."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}


variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "my-pg-cluster"
}

variable "cluster_description" {
  description = "Cluster description"
  type        = string
  default     = "PG cluster for tests"
}

variable "pg_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "pg_preset" {
  description = "Host class"
  type        = string
  default     = "s3-c2-m8"
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "network-ssd"
}

variable "db_disk_gb" {
  description = "Disk size, GB"
  type        = number
  default     = 20
}

variable "enable_public_ip" {
  description = "Assign public IP to host"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "app"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
