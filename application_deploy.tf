resource "aws_ssm_association" "labshop" {
  name             = "AWS-RunShellScript"
  association_name = "aws-lab-install-labshop"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.application.id]
  }

  parameters = {
    commands = replace(templatefile("${path.module}/labshop/install.sh", {
      app_base64 = filebase64("${path.module}/labshop/app.py")
    }), "\r\n", "\n")
  }
}