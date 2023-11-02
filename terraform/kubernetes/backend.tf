# Указываем путь где мы будем хранить наш stage file
terraform {
  backend "gcs" {
    bucket = "bucket-a7605dacc4e856c2" # имя нашего bucket
    prefix = "kuberbetes"
  }
}
