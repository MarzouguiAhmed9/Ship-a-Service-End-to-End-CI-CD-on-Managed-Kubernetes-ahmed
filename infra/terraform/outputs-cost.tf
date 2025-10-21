# ============================================================================
# COST TRACKING OUTPUTS
# ============================================================================
# File: outputs-cost.tf
# Purpose: Dedicated cost estimation and tracking outputs
# Author: MarzouguiAhmed9
# Date: 2025-10-18 19:26:30 UTC
# ============================================================================

# ----------------------------------------------------------------------------
# Cost Calculation Locals
# ----------------------------------------------------------------------------

locals {
  # AWS pricing for EC2 instances (us-east-1, October 2025)
  instance_pricing = {
    "t3.micro"  = 0.0104 # $7.59/month
    "t3.small"  = 0.0208 # $15.18/month
    "t3.medium" = 0.0416 # $30.37/month
    "t3.large"  = 0.0832 # $60.74/month
  }

  # Hours in a month (average)
  hours_per_month = 730

  # Cost per node per month
  cost_per_node_monthly = lookup(local.instance_pricing, var.node_type, 0.0416) * local.hours_per_month

  # Total worker nodes cost
  total_worker_cost = local.cost_per_node_monthly * var.node_desired

  # Fixed monthly costs
  fixed_costs = {
    eks_control_plane = 73.00
    ecr_storage       = 0.10
    cloudwatch_logs   = 2.50
    data_transfer     = 1.00
    nat_gateway       = 0.00 # Not using NAT Gateway
  }

  # Sum of fixed costs
  total_fixed_cost = sum(values(local.fixed_costs))

  # Total monthly cost
  total_cost_monthly = local.total_fixed_cost + local.total_worker_cost

  # Cost per hour
  cost_per_hour = local.total_cost_monthly / local.hours_per_month

  # Cost per day
  cost_per_day = local.cost_per_hour * 24

  # Cost per week
  cost_per_week = local.cost_per_day * 7

  # Annual cost
  cost_per_year = local.total_cost_monthly * 12

  # Savings calculations
  savings_scale_to_1 = local.cost_per_node_monthly * (var.node_desired - 1)
  savings_t3_small   = var.node_type == "t3.medium" ? (local.instance_pricing["t3.medium"] - local.instance_pricing["t3.small"]) * local.hours_per_month * var.node_desired : 0
  savings_destroy    = local.total_cost_monthly

  # Budget status
  budget_limit        = 150.00
  budget_used_percent = (local.total_cost_monthly / local.budget_limit) * 100
  budget_status       = local.total_cost_monthly > local.budget_limit ? "⚠️  OVER BUDGET" : local.total_cost_monthly > (local.budget_limit * 0.8) ? "⚠️  WARNING" : "✅ OK"
}

# ============================================================================
# PRIMARY COST OUTPUT
# ============================================================================

output "monthly_cost_estimate" {
  description = "💰 Complete monthly cost breakdown"
  value = {
    # Header
    infrastructure = "Ship-a-Service EKS Cluster"
    owner          = "MarzouguiAhmed9"
    generated_at   = "2025-10-18 19:26:30 UTC"

    # Configuration
    config = {
      cluster_name = var.cluster_name
      environment  = var.env
      region       = var.region
      node_type    = var.node_type
      node_count   = var.node_desired
    }

    # Cost breakdown
    breakdown = {
      eks_control_plane = format("$%.2f", local.fixed_costs.eks_control_plane)
      worker_nodes      = format("$%.2f (%dx %s @ $%.2f each)", local.total_worker_cost, var.node_desired, var.node_type, local.cost_per_node_monthly)
      ecr_storage       = format("$%.2f", local.fixed_costs.ecr_storage)
      cloudwatch_logs   = format("$%.2f", local.fixed_costs.cloudwatch_logs)
      data_transfer     = format("$%.2f", local.fixed_costs.data_transfer)
      separator         = "─────────────────────────────"
      total             = format("$%.2f/month", local.total_cost_monthly)
    }

    # Time-based costs
    time_periods = {
      hourly  = format("$%.4f", local.cost_per_hour)
      daily   = format("$%.2f", local.cost_per_day)
      weekly  = format("$%.2f", local.cost_per_week)
      monthly = format("$%.2f", local.total_cost_monthly)
      yearly  = format("$%.2f", local.cost_per_year)
    }

    # Budget tracking
    budget = {
      monthly_limit = format("$%.2f", local.budget_limit)
      current_spend = format("$%.2f", local.total_cost_monthly)
      percentage    = format("%.1f%%", local.budget_used_percent)
      remaining     = format("$%.2f", local.budget_limit - local.total_cost_monthly)
      status        = local.budget_status
    }

    # Potential savings
    savings = {
      scale_to_1_node = var.node_desired > 1 ? format("Save $%.2f/month", local.savings_scale_to_1) : "N/A (already 1 node)"
      use_t3_small    = local.savings_t3_small > 0 ? format("Save $%.2f/month", local.savings_t3_small) : "✓ Already optimized"
      destroy_all     = format("Save $%.2f/month", local.savings_destroy)
      spot_instances  = "Save ~70% (not implemented)"
    }
  }
}

# ============================================================================
# FORMATTED COST SUMMARY (Text Output)
# ============================================================================

output "cost_report" {
  description = "📊 Formatted cost report for documentation"
  value       = <<-EOT
  
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                 SHIP-A-SERVICE COST REPORT                           ║
  ║                 Infrastructure Cost Analysis                         ║
  ╚══════════════════════════════════════════════════════════════════════╝
  
  Report Generated: 2025-10-18 19:26:30 UTC
  Owner: MarzouguiAhmed9
  Cluster: ${var.cluster_name}
  Environment: ${var.env}
  Region: ${var.region}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ CONFIGURATION                                                        │
  └──────────────────────────────────────────────────────────────────────┘
  
    Node Type:          ${var.node_type}
    Node Count:         ${var.node_desired}
    Min Nodes:          ${var.node_min}
    Max Nodes:          ${var.node_max}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ MONTHLY COST BREAKDOWN                                               │
  └──────────────────────────────────────────────────────────────────────┘
  
    Service                          Unit Cost    Quantity      Total
    ────────────────────────────────────────────────────────────────────
    EKS Control Plane                $73.00          1         $${format("%.2f", local.fixed_costs.eks_control_plane)}
    Worker Nodes (${var.node_type})         $${format("%.2f", local.cost_per_node_monthly)}        ${var.node_desired}         $${format("%.2f", local.total_worker_cost)}
    ECR Container Registry           $0.10           1         $${format("%.2f", local.fixed_costs.ecr_storage)}
    CloudWatch Logs                  $2.50           1         $${format("%.2f", local.fixed_costs.cloudwatch_logs)}
    Data Transfer (estimate)         $1.00           1         $${format("%.2f", local.fixed_costs.data_transfer)}
    ────────────────────────────────────────────────────────────────────
    TOTAL MONTHLY COST                                         $${format("%.2f", local.total_cost_monthly)}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ COST BY TIME PERIOD                                                  │
  └──────────────────────────────────────────────────────────────────────┘
  
    Per Hour:    $${format("%.4f", local.cost_per_hour)}
    Per Day:     $${format("%.2f", local.cost_per_day)}
    Per Week:    $${format("%.2f", local.cost_per_week)}
    Per Month:   $${format("%.2f", local.total_cost_monthly)}
    Per Year:    $${format("%.2f", local.cost_per_year)}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ BUDGET STATUS                                                        │
  └──────────────────────────────────────────────────────────────────────┘
  
    Monthly Budget:      $${format("%.2f", local.budget_limit)}
    Current Spending:    $${format("%.2f", local.total_cost_monthly)}
    Budget Used:         ${format("%.1f", local.budget_used_percent)}%
    Remaining:           $${format("%.2f", local.budget_limit - local.total_cost_monthly)}
    Status:              ${local.budget_status}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ COST OPTIMIZATION OPPORTUNITIES                                      │
  └──────────────────────────────────────────────────────────────────────┘
  
    💡 Scale to 1 node:        ${var.node_desired > 1 ? format("Save $%.2f/month", local.savings_scale_to_1) : "Already at minimum"}
    💡 Use t3.small:           ${local.savings_t3_small > 0 ? format("Save $%.2f/month", local.savings_t3_small) : "Already optimized"}
    💡 Use Spot Instances:     Save ~70% on compute costs
    💡 Destroy when not used:  Save $${format("%.2f/month", local.savings_destroy)}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ RECOMMENDATIONS                                                      │
  └──────────────────────────────────────────────────────────────────────┘
  
    ${local.total_cost_monthly > local.budget_limit ? "⚠️  OVER BUDGET - Action required!\n\n    • Scale down to 1 node\n    • Use t3.small instead of t3.medium\n    • Enable auto-cleanup with TTL tags\n    • Destroy when not in active use" : local.total_cost_monthly > (local.budget_limit * 0.8) ? format("⚠️  WARNING - Using %.0f%% of budget\n\n    • Monitor usage closely\n    • Set up AWS Budget alerts\n    • Plan cleanup when testing complete", local.budget_used_percent) : "✅ Within budget\n\n    • Monitor costs: terraform output cost_report\n    • Set up AWS Budget alerts\n    • Use TTL tags for auto-cleanup\n    • Destroy when not needed"}
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ COST MANAGEMENT COMMANDS                                             │
  └──────────────────────────────────────────────────────────────────────┘
  
    # View this report
    terraform output cost_report
    
    # View JSON cost data
    terraform output monthly_cost_estimate
    
    # Scale down to save money
    terraform apply -var="node_desired=1"
    
    # Destroy to stop all charges
    terraform destroy
    
    # Check actual AWS costs
    aws ce get-cost-and-usage \
      --time-period Start=2025-10-01,End=2025-10-31 \
      --granularity MONTHLY \
      --metrics BlendedCost
  
  ══════════════════════════════════════════════════════════════════════
  Report ends. For questions, contact: MarzouguiAhmed9
  ══════════════════════════════════════════════════════════════════════
  
  EOT
}

# ============================================================================
# QUICK COST OUTPUTS
# ============================================================================

output "total_monthly_cost" {
  description = "Total monthly cost (quick reference)"
  value       = format("$%.2f", local.total_cost_monthly)
}

output "total_daily_cost" {
  description = "Total daily cost"
  value       = format("$%.2f", local.cost_per_day)
}

output "total_hourly_cost" {
  description = "Total hourly cost"
  value       = format("$%.4f", local.cost_per_hour)
}

output "budget_status" {
  description = "Budget status indicator"
  value       = local.budget_status
}

# ============================================================================
# COST COMPARISON TABLE
# ============================================================================

output "cost_comparison" {
  description = "Cost comparison for different configurations"
  value = {
    current_config = {
      setup       = "${var.node_desired}x ${var.node_type}"
      monthly     = format("$%.2f", local.total_cost_monthly)
      description = "Your current configuration"
    }
    minimal_config = {
      setup       = "1x t3.small"
      monthly     = format("$%.2f", 73.00 + (0.0208 * 730) + 0.10 + 2.50 + 1.00)
      description = "Cheapest production-viable option"
    }
    recommended_dev = {
      setup       = "1x t3.medium"
      monthly     = format("$%.2f", 73.00 + (0.0416 * 730) + 0.10 + 2.50 + 1.00)
      description = "Recommended for development"
    }
    recommended_prod = {
      setup       = "2x t3.medium"
      monthly     = format("$%.2f", 73.00 + (0.0416 * 730 * 2) + 0.10 + 2.50 + 1.00)
      description = "Recommended for production"
    }
  }
}

# ============================================================================
# COST METADATA
# ============================================================================

output "cost_metadata" {
  description = "Cost calculation metadata"
  value = {
    pricing_date       = "2025-10-18"
    pricing_region     = var.region
    pricing_source     = "AWS Pricing Calculator"
    calculation_method = "730 hours/month average"
    currency           = "USD"
    includes_tax       = false
    last_updated_by    = "MarzouguiAhmed9"
    last_updated_at    = "2025-10-18 19:26:30 UTC"
    terraform_version  = ">= 1.5.0"
  }
}