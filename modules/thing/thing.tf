resource "aws_iot_thing" "thing" {
  name = "${var.thing_group}-${var.thing_id}"
}

resource "aws_iot_thing_group_membership" "thing_group_membership" {
  thing_name             = aws_iot_thing.thing.name
  thing_group_name       = var.thing_group
  override_dynamic_group = true
}

resource "aws_iot_certificate" "thing_certificate" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "cert_attachment" {
  principal = aws_iot_certificate.thing_certificate.arn
  thing     = aws_iot_thing.thing.name
}

data "aws_arn" "thing" {
  arn = aws_iot_thing.thing.arn
}

data "aws_iam_policy_document" "thing_policy_document" {
  statement {
    sid = "connect"
    actions = [
      "iot:Connect"
    ]
    resources = [
      "arn:aws:iot:${data.aws_arn.thing.region}:${data.aws_arn.thing.account}:client/${var.thing_id}"
    ]
  }
  statement {
    sid = "communicate"
    actions = [
      "iot:Publish",
      "iot:Receive",
    ]
    resources = [
      "arn:aws:iot:${data.aws_arn.thing.region}:${data.aws_arn.thing.account}:topic/devices/${var.thing_group}/${var.thing_id}"
    ]
  }
  statement {
    sid = "subscribe"
    actions = [
      "iot:Subscribe"
    ]
    resources = [
      "arn:aws:iot:${data.aws_arn.thing.region}:${data.aws_arn.thing.account}:topicfilter/${var.thing_group}/${var.thing_id}"
    ]
  }
}

resource "aws_iot_policy" "thing_policy" {
  name   = "thing_policy_${aws_iot_thing.thing.name}"
  policy = data.aws_iam_policy_document.thing_policy_document.json
}

resource "aws_iot_policy_attachment" "policy_attachment" {
  policy = aws_iot_policy.thing_policy.name
  target = aws_iot_certificate.thing_certificate.arn
}

data "aws_iot_endpoint" "iot_endpoint" {
  endpoint_type = "iot:Data-ATS"
}
