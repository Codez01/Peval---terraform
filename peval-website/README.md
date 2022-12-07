# Peval Website

1.  Connected S3 Bucket with github flow, enabled ACL and static website hosting, bucket name: peval-website
2.  HTTP API when the user clicks generate report on a site.
3.  1. Lambda function containing selenium and a chrome driver connected to IAM user that has access to S3 bucket
    2. Time-out is set to 15 mins (MAX)
    3. more Memory
4.  JSON is sent to S3 bucket in the name of generation date
5.  Lambda responds witht the JSON url in S3 Bucket
6.  Lambda code is connected to github actions to CI the code
7.  enabled CORS in S3 bucket that saves the report:

        {
            "AllowedHeaders": [
                "*"
            ],
            "AllowedMethods": [
                "GET",
                "HEAD"
            ],
            "AllowedOrigins": [
                "*"
            ],
            "ExposeHeaders": []
        }

    ]

8.  policy for s3 that hosts the site:

{
"Version": "2012-10-17",
"Id": "Policy1670185059873",
"Statement": [
{
"Sid": "Stmt1670185054769",
"Effect": "Allow",
"Principal": "*",
"Action": "s3:GetObject",
"Resource": "arn:aws:s3:::peval.cf/*"
}
]
}


Added route53 to main bucket

![image](https://user-images.githubusercontent.com/80861363/204332819-8edbdeb4-5792-44ba-87b9-87d1edfe6792.png)
