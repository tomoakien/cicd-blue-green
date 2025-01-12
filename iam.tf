#ECSタスク用ロール作成
#AWSリソースにアクセスする場合は必ず指定する必要あり
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = templatefile("./src/assume_role.json.tpl", {
    resource = "ecs-tasks"
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  role   = aws_iam_role.ecs_task_role.name
  policy = templatefile("./src/ecs_task_policy.json.tpl", {})
}

#----------------------------------------------------------------
#ECSタスク実行用ロール
resource "aws_iam_role" "ecs_task_exe_role" {
  name               = "ecs_task_exe_role"
  assume_role_policy = templatefile("./src/assume_role.json.tpl", { resource = "ecs-tasks" })
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_exe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ----------------------------------------------------------------
#code build用のiamロール作成
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"
  assume_role_policy = templatefile("./src/assume_role.json.tpl", {
    resource = "codebuild"
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild_role.name
  policy = templatefile("./src/codebuild_policy.json.tpl", {
    region         = "ap-northeast-1",
    account_id     = var.account_id,
    codebuild_name = aws_codebuild_project.codebuild.name,
    bucket_name    = aws_s3_bucket.artifact.id
  })
}

# ----------------------------------------------------------------
#code pipeline用のiamロール作成

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"
  assume_role_policy = templatefile("./src/assume_role.json.tpl", {
    resource = "codepipeline"
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  role   = aws_iam_role.codepipeline_role.name
  policy = templatefile("./src/codepipeline_policy.json.tpl", {})
}

#----------------------------------------------------------------
#code deploy用のiamロール作成
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"
  assume_role_policy = templatefile("./src/assume_role.json.tpl", {
    resource = "codedeploy"
  })
}

resource "aws_iam_role_policy" "codedeploy" {
  role   = aws_iam_role.codedeploy_role.name
  policy = templatefile("./src/codedeploy_policy.json.tpl", {})
}
