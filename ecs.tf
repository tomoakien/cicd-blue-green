#ECSのタスク定義
resource "aws_ecs_task_definition" "task" {
  #タスク定義の名前
  family = "ctn-cicd-hdon"
  #cpu,memoryについて、fargateは必須0.25vcpu
  cpu    = 256
  memory = 512
  #デフォルトはawsvpc推奨。
  network_mode = "awsvpc"
  #EC2かFARGATEか
  requires_compatibilities = ["FARGATE"]
  #必須。コンテナ定義のリソース
  container_definitions = templatefile("./src/container_definitions.json.tpl", {
    container_name  = var.container_name,
    container_image = var.container_image
    }
  )

  #IAMロールを指定
  execution_role_arn = aws_iam_role.ecs_task_exe_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  lifecycle {
    ignore_changes = [
      cpu, memory, container_definitions
    ]
  }
}

#----------------------------------------------------------------
#クラスターの設定
resource "aws_ecs_cluster" "cluster" {
  name = "ctn-cicd-hdon-cluster"
}

#キャパシティプロバイダー
resource "aws_ecs_cluster_capacity_providers" "capacity" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE"]
}

#----------------------------------------------------------------
#サービスの設定
resource "aws_ecs_service" "service" {
  name             = "ctn-cicd-hdon-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  #更新の設定
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  #ロードバランサーの指定はここで行う
  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.app.id]
    subnets          = [aws_subnet.pri_1.id, aws_subnet.pri_2.id]
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count, load_balancer]
  }

  depends_on = [aws_lb.alb]
}

