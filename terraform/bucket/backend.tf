# Можем хранить terraform.tfstate файл в том же бакете который мы создаем этим терраформом
terraform {
  backend "gcs" {
    bucket = "bucket-a7605dacc4e856c2" # имя нашего bucket
    prefix = "bucket"
  }
}
