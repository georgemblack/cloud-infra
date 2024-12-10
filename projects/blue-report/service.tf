locals {
  version = "1.2.0"
}

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
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = "intake"
      image     = "242201310196.dkr.ecr.us-west-2.amazonaws.com/blue-report:${local.version}"
      essential = true
      command   = ["/intake"]
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
      cpu    = 256
      memory = 512
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region" = "us-west-2"
          "awslogs-group"  = aws_cloudwatch_log_stream.blue_report.name
          "awslogs-stream-prefix" : "intake"
        }
      }
    },
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecs_task_definition" "blue_report_aggregate" {
  family                   = "blue-report-aggregate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.service.arn
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = "intake"
      image     = "242201310196.dkr.ecr.us-west-2.amazonaws.com/blue-report:${local.version}"
      essential = true
      command   = ["/aggregate"]
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
      cpu    = 256
      memory = 512
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region" = "us-west-2"
          "awslogs-group"  = aws_cloudwatch_log_stream.blue_report.name
          "awslogs-stream-prefix" : "aggregate"
        }
      }
    },
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}


resource "aws_ecs_service" "blue_report_intake" {
  name            = "blue-report-intake"
  launch_type     = "FARGATE"
  desired_count   = 1
  cluster         = aws_ecs_cluster.blue_report.id
  task_definition = aws_ecs_task_definition.blue_report_intake.arn

  network_configuration {
    subnets          = [aws_subnet.blue_report_subnet_2a.id, aws_subnet.blue_report_subnet_2b.id, aws_subnet.blue_report_subnet_2c.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.blue_report.id]
  }

  depends_on = [aws_elasticache_serverless_cache.blue_report]
}

resource "aws_scheduler_schedule" "blue_report_aggregate" {
  name                = "blue-report-aggregate-schedule"
  schedule_expression = "rate(10 minutes)"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 2
  }


  target {
    arn      = aws_ecs_cluster.blue_report.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_retry_attempts = 0
    }

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.blue_report_aggregate.arn
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = [aws_subnet.blue_report_subnet_2a.id, aws_subnet.blue_report_subnet_2b.id, aws_subnet.blue_report_subnet_2c.id]
        assign_public_ip = true
        security_groups  = [aws_security_group.blue_report.id]
      }
    }
  }
}
