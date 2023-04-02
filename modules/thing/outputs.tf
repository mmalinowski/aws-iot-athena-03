resource "local_file" "thing_certificate_cert" {
  content  = aws_iot_certificate.thing_certificate.certificate_pem
  filename = "${var.outputs_path}/${var.thing_group}/${var.thing_id}/cert.pem"
}

resource "local_file" "thing_certificate_private_key" {
  content  = aws_iot_certificate.thing_certificate.private_key
  filename = "${var.outputs_path}/${var.thing_group}/${var.thing_id}/private.key"
}

output "iot_endpoint" {
  value = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}
