#******************** Provider AWS ********************
provider "aws" {
  region     = "us-east-2"
  access_key = file("Credentials/access_key.txt")
  secret_key = file("Credentials/secret_key.txt")
}
#******************** END END Provider AWS ********************

#*******************************************
#*** #set the domain name               #***  
variable "domainName" {                 #***
  default = "peval.cff"                 #***
  type    = string                      #***
}                                       #***        
                                        #***  
# add subscriptions to sns              #*** 
locals {                                #***
  emails = ["hannaba410@gmail.com"]     #***
}                                       #***                       
#*******************************************


# #******************** Bucket Resource  ********************

#create aws_s3_bucket_acl
resource "aws_s3_bucket_acl" "peval-terraform-acl" {
  bucket = aws_s3_bucket.peval-terraform.bucket
  acl    = "public-read"

}

resource "aws_s3_bucket_acl" "peval-terraform-reports-acl" {
  bucket = aws_s3_bucket.peval-terraform-reports.bucket
  acl    = "public-read"

}


#website bucket
resource "aws_s3_bucket" "peval-terraform" {
  bucket        = var.domainName
  force_destroy = true

}

#add all files in peval-website folder to peval-terraform bucket
resource "aws_s3_bucket_object" "peval-website" {
  bucket   = aws_s3_bucket.peval-terraform.id
  for_each = fileset("peval-website/", "**")
  key      = each.value
  source   = "peval-website/${each.value}"
  etag     = filemd5("peval-website/${each.value}")
}



#aws s3 bucket aws_s3_bucket_policy
resource "aws_s3_bucket_policy" "peval-terraform-policy" {
  bucket = aws_s3_bucket.peval-terraform.bucket
  policy = templatefile("Policies/peval-terraform-s3-policy.json", { bucket = aws_s3_bucket.peval-terraform.bucket })
}

#static website config for website bucket
resource "aws_s3_bucket_website_configuration" "peval-website-conf" {
  bucket = aws_s3_bucket.peval-terraform.bucket

  index_document {
    suffix = "index.html"
  }

}


#reports bucket
resource "aws_s3_bucket" "peval-terraform-reports" {
  bucket        = "peval-terraform-reports"
  force_destroy = true


}

#aws s3 bucket aws_s3_bucket_policy
resource "aws_s3_bucket_policy" "peval-terraform-reports-policy" {
  bucket = aws_s3_bucket.peval-terraform-reports.bucket
  policy = templatefile("Policies/peval-terraform-reports-s3-policy.json", { bucket = aws_s3_bucket.peval-terraform-reports.bucket })
}
# #******************** Bucket Resource  ********************




# ********************* Lambda Resource ********************


resource "aws_iam_policy" "bucket_fullaccess_policy" {
  name = "bucket_fullaccess_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket", "s3:*Object"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "sns_fullaccess_policy" {
  name = "sns_fullaccess_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish", "sns:Subscribe", "sns:ListSubscriptionsByTopic", "sns:CreateTopic"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_policy" "cloudWatch_fullaccess_policy" {
  name = "cloudwatch_fullaccess_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["cloudwatch:*"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = [aws_iam_policy.bucket_fullaccess_policy.arn, aws_iam_policy.sns_fullaccess_policy.arn, aws_iam_policy.cloudWatch_fullaccess_policy.arn]


}



resource "aws_lambda_function" "peval-terraform-lambda" {

  function_name = "peval-terraform-lambda"
  filename      = "Code_Packages/Lambda-Selenium.zip"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "python3.7"
  memory_size   = 3004
  timeout       = 900

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }
  layers = [aws_lambda_layer_version.lambda_layer-chromium.arn, aws_lambda_layer_version.lambda_layer-selenium.arn]


}

resource "aws_lambda_layer_version" "lambda_layer-chromium" {
  filename   = "Code_Packages/chromedriver.zip"
  layer_name = "lambda_layer_chromium"

  compatible_runtimes      = ["python3.7"]
  compatible_architectures = ["x86_64"]

}

resource "aws_lambda_layer_version" "lambda_layer-selenium" {
  filename   = "Code_Packages/selenium-package.zip"
  layer_name = "lambda_layer_selenium"

  compatible_runtimes      = ["python3.7"]
  compatible_architectures = ["x86_64"]
}
# *********************END END Lambda Resource ********************

# ********************* SNS Resource ********************


#sns topic 
resource "aws_sns_topic" "peval-terraform-sns" {
  name = "PevalReportGeneration"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
}

#sns subscription with an email
resource "aws_sns_topic_subscription" "peval-terraform-sns-subscription" {
  count     = length(local.emails)
  topic_arn = aws_sns_topic.peval-terraform-sns.arn
  protocol  = "email"
  endpoint  = local.emails[count.index]
}


# ********************* END END SNS Resource ********************


#************************ Api Gateway Resource ********************

resource "aws_api_gateway_rest_api" "peval-terraform-api" {
  name        = "peval-terraform-api"
  description = "This is the API for peval-terraform"
}

resource "aws_api_gateway_resource" "peval-terraform-api-proxy" {
  rest_api_id = aws_api_gateway_rest_api.peval-terraform-api.id
  parent_id   = aws_api_gateway_rest_api.peval-terraform-api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "peval-terraform-api-proxy" {
  rest_api_id   = aws_api_gateway_rest_api.peval-terraform-api.id
  resource_id   = aws_api_gateway_resource.peval-terraform-api-proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "peval-terraform-api-lambdaActivator" {
  rest_api_id             = aws_api_gateway_rest_api.peval-terraform-api.id
  resource_id             = aws_api_gateway_method.peval-terraform-api-proxy.resource_id
  http_method             = aws_api_gateway_method.peval-terraform-api-proxy.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.peval-terraform-lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "peval-terraform-api" {
  depends_on        = [aws_api_gateway_integration.peval-terraform-api-lambdaActivator]
  rest_api_id       = aws_api_gateway_rest_api.peval-terraform-api.id
  stage_name        = "peval-terraform-api"
  stage_description = "This is the stage for peval-terraform-api"
  description       = "This is the deployment for peval-terraform-api"
}

# allowing api gateway to access lambda
resource "aws_lambda_permission" "peval-terraform-api-lambdaExecPermit" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.peval-terraform-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.peval-terraform-api.execution_arn}/*/*"
}

# api gateway method response / resposne 200
resource "aws_api_gateway_method_response" "peval-terraform-api-proxy-response" {
  rest_api_id = aws_api_gateway_rest_api.peval-terraform-api.id
  resource_id = aws_api_gateway_resource.peval-terraform-api-proxy.id
  http_method = aws_api_gateway_method.peval-terraform-api-proxy.http_method
  status_code = "200"
}

output "api_gateway_url" {
  description = "API Gatway url exported to update the website code: "
  value       = aws_api_gateway_deployment.peval-terraform-api.invoke_url
}

#************************ END END Api Gateway Resource ********************


#************************ route53 Resource ********************

resource "aws_route53_zone" "peval-terraform-route53" {
  name = var.domainName
}

resource "aws_route53_record" "peval-terraform-route53" {
  depends_on = [aws_s3_bucket.peval-terraform, aws_s3_bucket_website_configuration.peval-website-conf]
  zone_id    = aws_route53_zone.peval-terraform-route53.zone_id
  name       = var.domainName
  type       = "A"

  alias {
    name                   = aws_s3_bucket.peval-terraform.website_endpoint
    zone_id                = aws_s3_bucket.peval-terraform.hosted_zone_id
    evaluate_target_health = false
  }
}

output "dns-addresses" {
  description = "DNS addresses exported to update a domain "
  value       = aws_route53_zone.peval-terraform-route53.name_servers
}

#************************ END END route53 Resource ********************
