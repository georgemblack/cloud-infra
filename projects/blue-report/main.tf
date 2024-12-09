resource "aws_ecr_repository" "blue_report" {
  name                 = "blue-report"
  image_tag_mutability = "MUTABLE"
}

resource "aws_cloudwatch_log_group" "blue_report" {
  name = "blue-report"
}

resource "aws_cloudwatch_log_stream" "blue_report" {
  name           = "blue-report"
  log_group_name = aws_cloudwatch_log_group.blue_report.name
}

resource "aws_elasticache_serverless_cache" "blue_report" {
  name                 = "blue-report-cache"
  engine               = "valkey"
  major_engine_version = "8"
  subnet_ids           = [aws_subnet.blue_report_subnet_2a.id, aws_subnet.blue_report_subnet_2b.id, aws_subnet.blue_report_subnet_2c.id]
  security_group_ids   = [aws_security_group.blue_report.id]
}

resource "aws_ecs_cluster" "blue_report" {
  name = "blue-report"
}

resource "aws_ecs_task_definition" "blue_report_intake" {
  family                   = "blue-report-intake"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  network_mode       = "awsvpc"
  cpu                = 1024
  memory             = 2048
  execution_role_arn = aws_iam_role.blue_report.arn
  container_definitions = jsonencode([
    {
      name      = "intake"
      image     = "242201310196.dkr.ecr.us-west-2.amazonaws.com/blue-report:1.2.0"
      essential = true
      command   = []
      environment = [
        {
          name  = "VALKEY_ADDRESS"
          value = "${aws_elasticache_serverless_cache.blue_report.endpoint[0].address}:${aws_elasticache_serverless_cache.blue_report.endpoint[0].port}"
        },
        {
          name  = "VALKEY_TLS_ENABLED"
          value = "true"
        }
      ]
      cpu    = 1024
      memory = 2048
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region" = "us-west-2"
          "awslogs-group"  = aws_cloudwatch_log_stream.blue_report.name
          "awslogs-stream-prefix" : "main"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "blue_report_intake" {
  name            = "blue-report-intake"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.blue_report.id
  task_definition = aws_ecs_task_definition.blue_report_intake.arn
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.blue_report_subnet_2a.id, aws_subnet.blue_report_subnet_2b.id, aws_subnet.blue_report_subnet_2c.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.blue_report.id]
  }

  depends_on = [aws_elasticache_serverless_cache.blue_report]
}
