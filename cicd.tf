#code build作成
#ver1のgithub tokenが非推奨の為、使用しない。
#認証はpipelineで行い、通ってからcode buildが動く。

resource "aws_codebuild_project" "codebuild" {
  name         = "ctn-cicd-build"
  description  = "Codebuild project"
  service_role = aws_iam_role.codebuild_role.arn
  #ここのブロックでどこのソースを使用するか決める
  #環境変数を使えるように変更
  source {
    type            = "GITHUB"
    location        = var.github_repository
    git_clone_depth = 0
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    #imageの指定をする事でbuildをamazon linuxかubuntuにするか決定する。
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    #dockerをビルドする為必須

    environment_variable {
      name  = "ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }

    environment_variable {
      name  = "TASK_FAMILY"
      value = aws_ecs_task_definition.task.family
    }
  }
  build_timeout = 60
}

# ----------------------------------------------------------------
# code pipeline作成

resource "aws_codepipeline" "pipeline" {
  name     = "ctn-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }

  #ソースステージ：Githubからソースを取得
  #トリガとしてGithubやCodeCommitのソースリポジトリを設定する。
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.github_full_repository_name
        BranchName           = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.codedeploy.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.deploy_group.deployment_group_name
        AppSpecTemplateArtifact        = "build_output"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "build_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

#----------------------------------------------------------------
#codedeploy作成
resource "aws_codedeploy_app" "codedeploy" {
  compute_platform = "ECS"
  name             = "codedeploy-fargate-cicd"
}

#codedeployグループ作成
resource "aws_codedeploy_deployment_group" "deploy_group" {
  app_name               = aws_codedeploy_app.codedeploy.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "codedeploy-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  #blue/green　デプロイメントの設定を行う。
  #デプロイ後ストップ。手動でgreen環境にしない限りblue環境を維持。
  #10分間、ブルー環境を維持する。
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }
    #成功時2分でブルーインスタンスを削除する
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 2
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http80.arn]
      }

      #テスト環境
      test_traffic_route {
        listener_arns = [aws_lb_listener.http9000.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

