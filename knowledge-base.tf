# - Knowledge Base Default OpenSearch -
locals {
  create_cwl      = var.create_default_kb && var.create_kb_log_group
  create_delivery = local.create_cwl || var.kb_monitoring_arn != null

  chunking_count = var.create_default_kb && (var.semantic_chunking_configuration || var.hierarchical_chunking_configuration || var.fixed_size_chunking_configuration) ? [1] : []
  chunking_strategy_values = var.fixed_size_chunking_configuration ? {
        chunking_strategy = var.chunking_strategy
        fixed_size_chunking_configuration  = { 
          max_tokens = var.chunking_max_tokens
          overlap_percentage = var.overlap_percentage
        }
  } : ( var.hierarchical_chunking_configuration ? {
    chunking_strategy = var.chunking_strategy
     hierarchical_chunking_configuration = {
        level_configuration = {
          
            max_tokens = var.level_max_tokens
          

        } 
        overlap_tokens = var.overlap_tokens
      }
    } : ( var.semantic_chunking_configuration ? {
          chunking_strategy = var.chunking_strategy
          semantic_chunking_configuration = {
              breakpoint_percentile_threshold = var.breakpoint_percentile_threshold
              buffer_size = var.buffer_size
              max_token = var.semantic_max_tokens
            }
        } : null)) 


  chunking_strategy = [for count in local.chunking_count : local.chunking_strategy_values]

  
}

resource "awscc_bedrock_knowledge_base" "knowledge_base_default" {
  count       = var.create_default_kb ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.kb_name}"
  description = var.kb_description
  role_arn    = var.kb_role_arn != null ? var.kb_role_arn : aws_iam_role.bedrock_knowledge_base_role[0].arn

  storage_configuration = {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration = {
      collection_arn    = awscc_opensearchserverless_collection.default_collection[0].arn
      vector_index_name = opensearch_index.default_oss_index[0].name
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
        vector_field   = var.vector_field
      }
    }
  }
  knowledge_base_configuration = {
    type = "VECTOR"
    vector_knowledge_base_configuration = {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }
}

# – Existing KBs –

# - Mongo –
resource "awscc_bedrock_knowledge_base" "knowledge_base_mongo" {
  count       = var.create_mongo_config ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.kb_name}"
  description = var.kb_description
  role_arn    = var.kb_role_arn != null ? var.kb_role_arn : aws_iam_role.bedrock_knowledge_base_role[0].arn
  tags        = var.kb_tags

  storage_configuration = {
    type = var.kb_storage_type

    mongo_db_atlas_configuration = {
      collection_name        = var.collection_name
      credentials_secret_arn = var.credentials_secret_arn
      database_name          = var.database_name
      endpoint               = var.endpoint
      vector_index_name      = var.vector_index_name
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
        vector_field   = var.vector_field
      }
      endpoint_service_name = var.endpoint_service_name
    }
  }
  knowledge_base_configuration = {
    type = var.kb_type
    vector_knowledge_base_configuration = {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }
}

# – OpenSearch –
resource "awscc_bedrock_knowledge_base" "knowledge_base_opensearch" {
  count       = var.create_opensearch_config ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.kb_name}"
  description = var.kb_description
  role_arn    = var.kb_role_arn != null ? var.kb_role_arn : aws_iam_role.bedrock_knowledge_base_role[0].arn
  tags        = var.kb_tags

  storage_configuration = {
    type = var.kb_storage_type
    opensearch_serverless_configuration = {
      collection_arn    = var.collection_arn
      vector_index_name = var.vector_index_name
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
        vector_field   = var.vector_field
      }
    }
  }
  knowledge_base_configuration = {
    type = var.kb_type
    vector_knowledge_base_configuration = {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }
}

# – Pinecone –
resource "awscc_bedrock_knowledge_base" "knowledge_base_pinecone" {
  count       = var.create_pinecone_config ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.kb_name}"
  description = var.kb_description
  role_arn    = var.kb_role_arn != null ? var.kb_role_arn : aws_iam_role.bedrock_knowledge_base_role[0].arn
  tags        = var.kb_tags

  storage_configuration = {
    type = var.kb_storage_type
    pinecone_configuration = {
      connection_string      = var.connection_string
      credentials_secret_arn = var.credentials_secret_arn
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
      }
      namespace = var.namespace
    }
  }
  knowledge_base_configuration = {
    type = var.kb_type
    vector_knowledge_base_configuration = {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }
}

# – RDS –
resource "awscc_bedrock_knowledge_base" "knowledge_base_rds" {
  count       = var.create_rds_config ? 1 : 0
  name        = "${random_string.solution_prefix.result}-${var.kb_name}"
  description = var.kb_description
  role_arn    = var.kb_role_arn != null ? var.kb_role_arn : aws_iam_role.bedrock_knowledge_base_role[0].arn
  tags        = var.kb_tags

  storage_configuration = {
    type = var.kb_storage_type
    rds_configuration = {
      credentials_secret_arn = var.credentials_secret_arn
      database_name          = var.database_name
      resource_arn           = var.resource_arn
      table_name             = var.table_name
      field_mapping = {
        metadata_field    = var.metadata_field
        primary_key_field = var.primary_key_field
        text_field        = var.text_field
        vector_field      = var.vector_field
      }
    }
  }
  knowledge_base_configuration = {
    type = var.kb_type
    vector_knowledge_base_configuration = {
      embedding_model_arn = var.kb_embedding_model_arn
    }
  }
}

# - Knowledge Base Data source –
resource "awscc_s3_bucket" "s3_data_source" {
  count       = var.kb_s3_data_source == null && var.create_default_kb == true ? 1 : 0
  bucket_name = "${random_string.solution_prefix.result}-${var.kb_name}-default-bucket"

  tags = [{
    key   = "Name"
    value = "S3 Data Source"
  }]

}

resource "aws_bedrockagent_data_source" "knowledge_base_ds" {
  count             = var.create_default_kb ? 1 : 0
  knowledge_base_id = awscc_bedrock_knowledge_base.knowledge_base_default[0].id
  name              = "${random_string.solution_prefix.result}-${var.kb_name}DataSource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.kb_s3_data_source == null ? awscc_s3_bucket.s3_data_source[0].arn : var.kb_s3_data_source # Create an S3 bucket or reference existing
    }
  }
  vector_ingestion_configuration { 
    chunking_configuration {
      chunking_strategy = var.chunking_strategy
    } 
    
    custom_transformation_configuration {
      intermediate_storage {
        s3_location {
          uri = var.s3_location_uri
        } 
      }
      transformation {
        step_to_apply = var.step_to_apply
        transformation_function {
          transformation_lambda_configuration {
            lambda_arn = var.lambda_arn_transformation
          }
        }
      }
  
    }
    parsing_configuration { 
      bedrock_foundation_model_configuration {
        model_arn = var.model_arn
        parsing_prompt {
          parsing_prompt_string = var.parsing_prompt_string
        }
      }
      parsing_strategy = var.parsing_strategy
    }
  }
}

resource "aws_cloudwatch_log_group" "knowledge_base_cwl" {
  #tfsec:ignore:log-group-customer-key
  #checkov:skip=CKV_AWS_158:Encryption not required for log group
  count             = local.create_cwl ? 1 : 0
  name              = "/aws/vendedlogs/bedrock/knowledge-base/APPLICATION_LOGS/${awscc_bedrock_knowledge_base.knowledge_base_default[0].id}"
  retention_in_days = var.kb_log_group_retention_in_days
}

resource "awscc_logs_delivery_source" "knowledge_base_log_source" {
  count        = local.create_delivery ? 1 : 0
  name         = "${random_string.solution_prefix.result}-${var.kb_name}-delivery-source"
  log_type     = "APPLICATION_LOGS"
  resource_arn = awscc_bedrock_knowledge_base.knowledge_base_default[0].knowledge_base_arn
}

resource "awscc_logs_delivery_destination" "knowledge_base_log_destination" {
  count                    = local.create_delivery ? 1 : 0
  name                     = "${random_string.solution_prefix.result}-${var.kb_name}-delivery-destination"
  output_format            = "json"
  destination_resource_arn = local.create_cwl ? aws_cloudwatch_log_group.knowledge_base_cwl[0].arn : var.kb_monitoring_arn
  tags = [{
    key   = "Name"
    value = "${random_string.solution_prefix.result}-${var.kb_name}-delivery-destination"
  }]
}

resource "awscc_logs_delivery" "knowledge_base_log_delivery" {
  count                    = local.create_delivery ? 1 : 0
  delivery_destination_arn = awscc_logs_delivery_destination.knowledge_base_log_destination[0].arn
  delivery_source_name     = awscc_logs_delivery_source.knowledge_base_log_source[0].name
  tags = [{
    key   = "Name"
    value = "${random_string.solution_prefix.result}-${var.kb_name}-delivery"
  }]
}
