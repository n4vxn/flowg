###############################################################################
# DESCRIPTION: Test pipeline management through API
###############################################################################

# -----------------------------------------------------------------------------
# TEST:
#  - Verify that the default pipeline exists

GET http://localhost:5080/api/v1/pipelines
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.pipelines" count == 1
jsonpath "$.pipelines[0]" == "default"

GET http://localhost:5080/api/v1/pipelines/default
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.flow" exists

# -----------------------------------------------------------------------------
# TEST:
#  - Verify the a pipeline "test" does not exist
#  - Create a new pipeline "test" that route logs to the stream "test"
#  - Verify it appears in the list of pipelines

GET http://localhost:5080/api/v1/pipelines/test
Authorization: Bearer {{admin_token}}
HTTP 404

PUT http://localhost:5080/api/v1/pipelines/test
Authorization: Bearer {{admin_token}}
Content-Type: application/json
{
  "flow": {
    "nodes": [
      {
        "id": "__builtin__source_direct",
        "type": "source",
        "position": {"x": 210, "y": 195},
        "deletable": false,
        "data": {"type": "direct"},
        "measured": {"width": 136, "height": 38},
        "selected": true,
        "dragging": false
      },
      {
        "id": "__builtin__source_syslog",
        "type": "source",
        "position": {"x": 210, "y": 250},
        "deletable": false,
        "data": {"type": "syslog"},
        "measured": {"width": 136, "height": 38},
        "selected": true,
        "dragging": false
      },
      {
        "id": "node-1",
        "type": "router",
        "position": {"x": 405, "y": 195},
        "data": {"stream": "test"},
        "measured": {"width": 241,"height": 91},
        "selected": false,
        "dragging": false
      }
    ],
    "edges": [
      {
        "id": "xy-edge____builtin__source_direct-node-1",
        "type": "smoothstep",
        "source": "__builtin__source_direct",
        "target": "node-1",
        "animated": true
      },
      {
        "id": "xy-edge____builtin__source_syslog-node-1",
        "type": "smoothstep",
        "source": "__builtin__source_syslog",
        "target": "node-1",
        "animated": true
      }
    ]
  }
}
HTTP 200
[Asserts]
jsonpath "$.success" == true

GET http://localhost:5080/api/v1/pipelines
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.pipelines" count == 2
jsonpath "$.pipelines" contains "default"
jsonpath "$.pipelines" contains "test"

# -----------------------------------------------------------------------------
# TEST:
#  - Send structured logs to the "test" pipeline
#  - Verify logs have been ingested in the "test" stream
#  - Purge the stream

POST http://localhost:5080/api/v1/pipelines/test/logs/struct
Authorization: Bearer {{admin_token}}
Content-Type: application/json
{
  "records": [
    {
      "level": "info",
      "message": "test"
    }
  ]
}
HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.processed_count" == 1

GET http://localhost:5080/api/v1/streams/test/logs
Authorization: Bearer {{admin_token}}
[Query]
from: {{timewindow_begin}}
to: {{timewindow_end}}

HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.records" count == 1
jsonpath "$.records[0].fields.level" == "info"
jsonpath "$.records[0].fields.message" == "test"

DELETE http://localhost:5080/api/v1/streams/test
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true

# -----------------------------------------------------------------------------
# TEST:
#  - Delete the "test" pipeline
#  - Verify it no longer appears in the list of pipelines

DELETE http://localhost:5080/api/v1/pipelines/test
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true

GET http://localhost:5080/api/v1/pipelines/test
Authorization: Bearer {{admin_token}}
HTTP 404

GET http://localhost:5080/api/v1/pipelines
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.success" == true
jsonpath "$.pipelines" not contains "test"
