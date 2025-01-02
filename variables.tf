variable "tags" {
  type        = map(string)
  description = " A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  }
}

variable "gitlab_repos" {
  description = <<EOF
    Repository list where workflows that will access this role live.
    This is to ensure that only that repo has access to this role.
    Example:
    [
      "project_path:mygroup/myproject:ref_type:branch:ref:main",
      "project_path:mygroup/myproject:*"
    ]
  EOF
  type        = list(string)
  validation {
    condition     = length([for s in var.gitlab_repos : substr(s, 0, 13) == "project_path:" if substr(s, 0, 13) == "project_path:"]) == length(var.gitlab_repos)
    error_message = "All repos must start with 'project_path:'"
  }
}

variable "role_policies" {
  description = "IAM policies to be assigned to the role. Format is whatever_name = arn_of_policy."
  type        = map(string)
  default     = {}
}

variable "role_name" {
  description = "name of the role to create in AWS"
  type        = string
  default     = "GitLabPipelineRole"
}
