# Registry Governance System Specification

## 1. Overview

The Registry Governance system provides a centralized architecture for managing registry operations in the Wippy Runtime environment. It ensures data consistency, validation, and provides hooks for preprocessing and postprocessing of registry changes.

### 1.1 Key Components

The system consists of several core components:

1. **Client Interface** (`keeper.gov:client`) - Public API for initiating registry operations
2. **Governance Process** (`keeper.gov:process`) - Central controller service
3. **Change Pipeline**:
    - Pre-processor - Validates and transforms changesets
    - Executor - Applies changes to registry
    - Post-processor - Handles notifications and side effects
4. **Extension Points**:
    - Processors - Validate and transform changesets before application
    - Listeners - React to registry changes after they're applied

### 1.2 Data Flow

1. Client submits a request to the governance process
2. Request is validated and preprocessed by processors
3. Changes are applied to the registry
4. Listeners are notified of the changes
5. Result is returned to the client

## 2. Client Interface

### 2.1 Loading the Module

```lua
local registry_client = require("keeper.gov:client")
```

### 2.2 Security Requirements

All client operations require appropriate security permissions:

| Operation | Required Permission |
|-----------|---------------------|
| Read operations | `registry.request.read` |
| Write operations | `registry.request.write` |
| Version operations | `registry.request.version` |
| Sync operations | `registry.request.sync` |

### 2.3 Common Parameters

Most client functions accept these common parameters:

- **options** (table, optional): Operation-specific configuration
- **timeout** (string, optional): Request timeout as a duration string (default: "600s"). Format: number followed by unit suffix (e.g., "5s", "30s", "10m")

### 2.4 Function Reference

#### 2.4.1 Get System State

```lua
local state, err = registry_client.get_state([options], [timeout])
```

Retrieves the current state of the registry governance system.

**Parameters:**
- **options** (table, optional): Additional options (currently unused)
- **timeout** (string, optional): Request timeout as a duration string (e.g., "5s", "30s")

**Returns on success:**
```lua
{
  registry = {
    current_version = number, -- Current registry version
    timestamp = number        -- Unix timestamp
  },
  governance = {
    status = string,          -- Status of governance process (e.g., "running")
    pid = string,             -- Process ID
    operation_in_progress = boolean,
    current_operation = string,
    last_operation_type = string,
    last_updated = number     -- Unix timestamp
  },
  changes = {
    filesystem_changes_pending = boolean,
    registry_changes_pending = boolean
  }
}
```

**Returns on error:**
- `nil, error_message`

#### 2.4.2 Request Changes

```lua
local result, err = registry_client.request_changes(changeset, [options], [timeout])
```

Applies a changeset to the registry.

**Parameters:**
- **changeset** (table or changeset object): Set of changes to apply
    - If passing a table, each entry should be a change operation (see Section 3)
    - If passing a changeset object (from `snapshot:changes()`), it will be automatically extracted
- **options** (table, optional): Additional options
- **timeout** (string, optional): Request timeout as a duration string (e.g., "30s", "10m")

**Returns on success:**
```lua
{
  version = number,            -- New registry version
  message = string,            -- Success message
  details = table,             -- Additional details (if available)
  changeset = table            -- Applied changes
}
```

**Returns on error:**
- `nil, error_message`

#### 2.4.3 Request Version

```lua
local result, err = registry_client.request_version(version_id, [options], [timeout])
```

Rolls back or forward to a specific registry version.

**Parameters:**
- **version_id** (string or number): The version ID to apply
- **options** (table, optional): Additional options
- **timeout** (string, optional): Request timeout as a duration string (e.g., "30s", "10m")

**Returns on success:**
```lua
{
  version = string,            -- Applied version ID
  message = string,            -- Success message
  details = table,             -- Additional details (if available)
  changeset = table            -- Changes applied during rollback
}
```

**Returns on error:**
- `nil, error_message`

#### 2.4.4 Request Download

```lua
local result, err = registry_client.request_download([options], [timeout])
```

Downloads registry data from an external source (if configured).

**Parameters:**
- **options** (table, optional): Additional options
    - source (string, optional): Download source
    - filters (table, optional): Filters to apply during download
- **timeout** (string, optional): Request timeout as a duration string (e.g., "90s", "10m")

**Returns on success:**
```lua
{
  version = number,            -- Current registry version
  stats = {                    -- Download statistics
    entries_processed = number,
    entries_added = number,
    entries_updated = number,
    entries_skipped = number,
    duration_ms = number
  },
  message = string,            -- Success message
  details = table,             -- Additional details (if available)
  changeset = table            -- Changes applied (if any)
}
```

**Returns on error:**
- `nil, error_message`

#### 2.4.5 Request Upload

```lua
local result, err = registry_client.request_upload([options], [timeout])
```

Uploads registry data to an external destination (if configured).

**Parameters:**
- **options** (table, optional): Additional options
    - destination (string, optional): Upload destination
    - filters (table, optional): Filters to apply during upload
- **timeout** (string, optional): Request timeout as a duration string (e.g., "90s", "10m")

**Returns on success:**
```lua
{
  version = number,            -- Current registry version
  stats = {                    -- Upload statistics
    entries_processed = number,
    entries_uploaded = number,
    entries_skipped = number,
    duration_ms = number
  },
  message = string,            -- Success message
  details = table,             -- Additional details (if available)
  changeset = table            -- Changes applied (if any)
}
```

**Returns on error:**
- `nil, error_message`

## 3. Registry Structure and Changeset Format

### 3.1 Registry Entry Structure

Registry entries must adhere to a specific structure, depending on their purpose:

1. **Registry Configuration Entries**:
    - Always use `kind = "registry.entry"` for registry-level configurations
    - Specify the actual entry type using `meta.type` (e.g., `meta.type = "view.page"`)
    - Only runtime-created entries may have different kinds (e.g., "function.lua", "process.lua")

2. **Entry Identification**:
    - Entries are always identified using `namespace:name` format
    - Specified as `id = "namespace:name"`

3. **Metadata and Data**:
    - `meta` table contains metadata about the entry (including `type`)
    - `data` table contains the actual entry data

### 3.2 Changeset Structure

A changeset is an array of change operations, where each operation has a specific structure:

```lua
-- A change operation within a changeset
{
  kind = string,  -- Operation type: "entry.create", "entry.update", or "entry.delete"
  entry = {       -- Entry being operated on
    id = string,  -- Entry ID in "namespace:name" format (required for updates/deletes)
    
    -- Required for create and update operations:
    kind = "registry.entry",  -- Always use "registry.entry" for registry configs
    meta = {
      type = string,         -- Actual entry type (REQUIRED)
      -- Other metadata key-value pairs
    },
    data = {                 -- Entry data
      -- Any key-value pairs
    }
  }
}
```

### 3.3 Example Changeset

```lua
local changeset = {
  -- Create a new entry
  {
    kind = "entry.create",
    entry = {
      id = "services:database",
      kind = "registry.entry",
      meta = {
        type = "service.database",  -- Specify the ACTUAL type here
        environment = "production",
        owner = "platform-team"
      },
      data = {
        port = 5432,
        limits = {
          memory = "1Gi",
          cpu = "0.5"
        }
      }
    }
  },
  
  -- Update an existing entry
  {
    kind = "entry.update",
    entry = {
      id = "config:rate-limits",
      kind = "registry.entry",
      meta = {
        type = "config.limits",
        updated = os.time(),
        revision = 3
      },
      data = {
        rate = 100,
        burst = 200
      }
    }
  },
  
  -- Delete an entry
  {
    kind = "entry.delete",
    entry = {
      id = "services:deprecated-service"
    }
  }
}
```

## 4. Processor Architecture

The governance system uses a multi-stage processing pipeline with detailed information passing between stages.

### 4.1 Processing Pipeline

1. **Pre-validation** - Basic validation of changesets or version IDs
2. **Processor chain** - Dynamic chain of custom processors for validation and transformation
3. **Execution** - Applying changes to the registry
4. **Post-processing** - Notification and side effects

### 4.2 Details Structure

Processors and validators communicate validation issues and information through a standardized "details" structure:

```lua
{
  -- Each detail is an item in the array
  {
    id = string,       -- MUST be the entry ID (e.g., "services:api") 
                       -- Use "item:N" only if entry ID not available
    type = string,     -- Type of detail (e.g., "validation", "warning", "info")
    message = string,  -- Human-readable message describing the issue
    -- Optional additional keys specific to the processor
    severity = string, -- Optional severity level
    metadata = {}      -- Optional additional context
  },
  -- More details...
}
```

Details are aggregated through the processing pipeline and ultimately returned to the client. This allows for comprehensive error reporting and debugging information.

### 4.3 Options Propagation

Options passed to client functions are propagated through the entire processing pipeline:

1. Client provides options (may include authentication tokens, context flags, etc.)
2. Options are passed to the pre-processor stage
3. Processors receive options and can access them for context
4. Processors can modify options (add or update keys)
5. Modified options propagate to subsequent processors
6. Final options are passed to the executor stage
7. Options are returned to the client in the result

### 4.4 Custom Return Keys

Processors can return custom keys in their result tables that will be propagated through the pipeline:

```lua
-- Example processor result with custom keys
return {
  success = true,
  changeset = processed_changeset,
  message = "Processing successful",
  -- Custom keys
  stats = {                    -- Custom statistics
    entries_validated = 10,
    warnings_found = 2 
  },
  metadata = {                 -- Custom metadata
    processor_version = "1.2.3"
  }
  -- All these custom keys will be propagated
}
```

The custom keys are accumulated and passed to subsequent processors and eventually returned to the client. This enables processors to:

1. Pass contextual information between pipeline stages
2. Add supplementary information to the final result
3. Build on or modify information from previous processors

## 5. Extending the Governance System

The Registry Governance system supports two main extension points:

1. **Processors** - Pre-process and validate registry changesets
2. **Listeners** - React to registry changes after they're applied

### 5.1 Creating a Custom Processor

Processors run before registry operations are applied. They can:
- Validate changesets
- Transform changesets
- Enforce business rules and policies
- Reject invalid changes
- Pass additional context between pipeline stages

#### 5.1.1 Processor Structure

```lua
-- File: my_processor.lua
local logger = require("logger")

local log = logger:named("custom.processor")

-- Main run function for processing
local function run(args)
    log:info("Starting custom processor")

    -- Validate arguments
    if not args or not args.changeset then
        return {
            success = false,
            message = "No changeset provided"
        }
    end

    -- Access options for context (security tokens, flags, etc.)
    local options = args.options or {}
    local request_id = args.request_id or "unknown"
    
    -- Track validation errors
    local validation_errors = {}
    
    -- Process each changeset item
    for i, op in ipairs(args.changeset) do
        -- Validate entry structure - IMPORTANT: Notice how we check kind and meta.type
        if op.entry and op.entry.kind == "registry.entry" and op.entry.meta and op.entry.meta.type == "my.special.type" then
            -- Check for required fields (note, no data for delete operations)
            if op.kind ~= "entry.delete" and (not op.entry.data or not op.entry.data.required_field) then
                table.insert(validation_errors, {
                    id = op.entry.id or "unknown",
                    type = "validation",
                    message = "Required field missing: required_field"
                })
            end
        end
    end

    -- Return validation errors if any
    if #validation_errors > 0 then
        -- Create formatted error message
        local error_msg = "Custom validation failed:\n"
        for i, err in ipairs(validation_errors) do
            error_msg = error_msg .. string.format("- Entry %s: %s\n",
                err.id,
                err.message
            )
        end

        return {
            success = false,
            message = error_msg,
            details = validation_errors  -- Return the details array
        }
    end

    -- Return success with unmodified changeset
    -- Add custom keys that will be propagated through the pipeline
    return {
        success = true,
        changeset = args.changeset,
        message = "Successfully processed changeset",
        custom_metadata = {              -- Custom keys will be propagated
            processor_name = "my_processor",
            processed_at = os.time()
        }
    }
end

-- Export the run function only
return { run = run }
```

#### 5.1.2 Processor Registry Entry

To register your processor, add an entry to the registry:

```yaml
version: "1.0"
namespace: my.processors

entries:
  - name: my_processor
    kind: function.lua
    meta:
      type: registry.processor          # Important: marks this as a processor
      comment: My custom processor
      description: Validates special entries and enforces business rules
      priority: 8000                    # Lower numbers run first
    source: file://my_processor.lua
    modules:
      - logger
      - json
    method: run
```

### 5.2 Creating a Custom Listener

Listeners run after registry changes are applied. They can:
- React to changes
- Send notifications
- Update related systems
- Log audit trails

#### 5.2.1 Listener Structure

```lua
-- File: my_listener.lua
local logger = require("logger")
local json = require("json")

local log = logger:named("custom.listener")

-- Main run function for the listener
local function run(args)
    log:info("Starting custom listener")

    -- Validate arguments
    if not args or not args.changeset or not args.result then
        log:warn("Invalid arguments provided to listener")
        return {
            success = false,
            message = "Invalid arguments"
        }
    end

    local changeset = args.changeset
    local result = args.result
    local request_id = args.request_id or "unknown"
    local options = args.options or {}  -- Access options for context

    -- Process changeset - IMPORTANT: Notice how we check kind and meta.type
    for _, op in ipairs(changeset) do
        if op.kind == "entry.create" or op.kind == "entry.update" then
            -- Check for registry.entry with specific meta.type
            if op.entry and op.entry.kind == "registry.entry" and 
               op.entry.meta and op.entry.meta.type == "my.special.type" then
                log:info("Special entry changed", {
                    id = op.entry.id,
                    type = op.entry.meta.type,
                    operation = op.kind,
                    request_id = request_id
                })                           
            end
        end
    end

    -- Return success
    return {
        success = true
    }
end

return { run = run }
```

#### 5.2.2 Listener Registry Entry

To register your listener, add an entry to the registry:

```yaml
version: "1.0"
namespace: my.listeners

entries:
  - name: my_listener
    kind: function.lua
    meta:
      type: registry.listener           # Important: marks this as a listener
      comment: My custom listener
      description: Reacts to changes in special entries
      priority: 50                      # Lower numbers run first
    source: file://my_listener.lua
    modules:
      - logger
      - json
    method: run
```

## 6. Usage Examples

### 6.1 Applying Changes

```lua
local client = require("keeper.gov:client")
local registry = require("registry")

-- Create a changeset manually
local changeset = {
    {
        kind = "entry.create",
        entry = {
            id = "services:api",
            kind = "registry.entry",
            meta = {
                type = "service.api",      -- Specify the actual type here
                environment = "production",
                owner = "platform-team"
            },
            data = {
                port = 8080
            }
        }
    }
}

-- Apply changes
local result, err = client.request_changes(changeset)
if not result then
    print("Error applying changes:", err)
    return
end

print("Changes applied, new version:", result.version)

-- Check for details from processors
if result.details and #result.details > 0 then
    print("Processing details:")
    for i, detail in ipairs(result.details) do
        print(string.format("%d. [%s] %s: %s", 
            i, detail.type, detail.id, detail.message))
    end
end

-- Check for custom metadata from processors
if result.custom_metadata then
    print("Custom metadata:", json.encode(result.custom_metadata))
end
```

### 6.2 Rolling Back to a Previous Version

```lua
local client = require("keeper.gov:client")

-- Roll back to version 42
local result, err = client.request_version(42)
if not result then
    print("Error applying version:", err)
    return
end

print("Successfully rolled back to version 42")
```

### 6.3 Checking System State

```lua
local client = require("keeper.gov:client")

local state, err = client.get_state()
if not state then
    print("Error getting state:", err)
    return
end

print("Current registry version:", state.registry.current_version)
print("Operation in progress:", state.governance.operation_in_progress)

-- Check if an operation is in progress before starting a new one
if state.governance.operation_in_progress then
    print("Operation in progress:", state.governance.current_operation)
    return
end
```

## 7. Error Handling

All client functions follow the Lua convention of returning `nil` and an error message string on failure. Errors can occur for various reasons:

- Permission denied
- Invalid changeset format
- Governance process not available
- Operation timeout
- Internal processing error
- Validation failure in processors

### 7.1 Error Response Format

```lua
{
  success = false,
  message = string,            -- Human-readable error message
  error = string,              -- Specific error details
  details = {                  -- Optional array of detailed errors
    {
      id = string,             -- Entry ID or item reference
      type = string,           -- Error type (e.g., "validation")
      message = string         -- Specific error message
    }
    -- More error details...
  }
}
```

## 8. Concurrency Considerations

The governance system supports only one operation at a time. If you attempt to start a new operation while another is in progress, the request will fail with an error message indicating that another operation is already running.

You can check if an operation is in progress by using the `get_state()` function and examining the `governance.operation_in_progress` field.