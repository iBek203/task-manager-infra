resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/${var.project}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # ── Row 1: RDS ───────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS CPU Utilization (%)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          yAxis  = { left = { min = 0, max = 100 } }
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project}-postgres"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS Database Connections"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project}-postgres"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS Free Storage (GB)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            [{ expression = "m1/1024/1024/1024", label = "Free Storage GB", id = "e1" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.project}-postgres", { id = "m1", visible = false }]
          ]
        }
      },

      # ── Row 2: ALB ───────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer}', 'RequestCount', 60)", id = "e1" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB HTTP 5xx Errors"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer}', 'HTTPCode_Target_5XX_Count', 60)", id = "e1" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Target Response Time (p90, s)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "p90"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer}', 'TargetResponseTime', 60)", id = "e1" }]
          ]
        }
      },

      # ── Row 3: Logs ──────────────────────────────────────────────────────────
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Application Errors (last 1 h)"
          region = var.aws_region
          view   = "table"
          query  = "SOURCE '/aws/eks/${var.project}/app' | fields @timestamp, @message | filter @message like /(?i)(error|exception|traceback)/ | sort @timestamp desc | limit 50"
        }
      }
    ]
  })
}
