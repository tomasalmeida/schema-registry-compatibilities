# Schema registry compatibility

## Proposal

Test the creation of new schemas based on the compatibility table in https://docs.confluent.io/platform/current/schema-registry/fundamentals/avro.html#compatibility-types




## Running the demo

```shell
    docker-compose up -d
```

### BACKWARD compatible
Steps:
- Open Control center http://localhost:9021/clusters
- Go to Cluster > Topics
- Create a topic `topic_backward`
- Click on schema > set a schema

```json
{
  "type": "record",
  "namespace": "com.mycorp.mynamespace",
  "name": "sampleRecord",
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "name": "my_field1",
      "type": "int",
      "doc": "The int type is a 32-bit signed integer."
    },
    {
      "name": "my_field2",
      "type": "double",
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number."
    },
    {
      "name": "my_field3",
      "type": "string",
      "doc": "The string is a unicode character sequence."
    }
  ]
}
```
- Produce to the topic

```shell

# start producer
kafka-avro-console-producer --broker-list localhost:19092 --topic topic_backward --property schema.registry.url=http://localhost:8081 --property value.schema.id=1 --property auto.register=false --property use.latest.version=false

#value to add
{"my_field1":1,"my_field2":1.1,"my_field3":"text"}


# consume data
kafka-avro-console-consumer --bootstrap-server localhost:19092 --topic topic_backward --property schema.registry.url=http://localhost:8081 --property print.schema.ids=true --from-beginning
```

- Go to control center > topic > Click on schema > Evolve schema

- Try to add a mandatory field > it should fail
```json
{
  "type": "record",
  "namespace": "com.mycorp.mynamespace",
  "name": "sampleRecord",
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "name": "my_field1",
      "type": "int",
      "doc": "The int type is a 32-bit signed integer."
    },
    {
      "name": "my_field2",
      "type": "double",
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number."
    },
    {
      "name": "my_field3",
      "type": "string",
      "doc": "The string is a unicode character sequence."
    },
    {
      "name": "mandatory_field",
      "type": "string",
      "doc": "This change should not be allowed as backward does not allow mandatory new fields"
    }
  ]
}
```
- Try to delete a field and add an optional field (note the field3 was deleted)
```json
{
  "type": "record",
  "namespace": "com.mycorp.mynamespace",
  "name": "sampleRecord",
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "name": "my_field1",
      "type": "int",
      "doc": "The int type is a 32-bit signed integer."
    },
    {
      "name": "my_field2",
      "type": "double",
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number."
    },
    {
      "name": "optional_field",
      "default": null,
      "type": ["null", "string"],
      "doc": "This change should be allowed as backward compatible"
    }
  ]
}
```
- Save it
- Produce to the topic

```shell

# start producer
kafka-avro-console-producer --broker-list localhost:19092 --topic topic_backward --property schema.registry.url=http://localhost:8081 --property value.schema.id=2 --property auto.register=false --property use.latest.version=false

#value to add
{"my_field1":1,"my_field2":1.1,"optional_field":{"string": "text"}}
{"my_field1":1,"my_field2":1.1,"optional_field": null}
{"my_field1":1,"my_field2":1.1} <-- fail as the optional_field cannot be guessed (https://forum.confluent.io/t/issues-with-optional-fields-when-using-avro-schema/1628)


# consume data
kafka-avro-console-consumer --bootstrap-server localhost:19092 --topic topic_backward --property schema.registry.url=http://localhost:8081 --property print.schema.ids=true
```

### FORWARD compatible
Steps:
- Open Control center http://localhost:9021/clusters
- Go to Cluster > Topics
- Create a topic `topic_forward`
- Click on schema > set a schema

```json
{
  "type": "record",
  "namespace": "com.mycorp.mynamespace",
  "name": "sampleRecord",
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "name": "my_field1",
      "type": "int",
      "doc": "The int type is a 32-bit signed integer."
    },
    {
      "name": "my_field2",
      "type": "double",
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number."
    },
    {
      "name": "my_field3",
      "type": "string",
      "doc": "The string is a unicode character sequence."
    }
  ]
}
```
- Produce to the topic

```shell

# start producer
kafka-avro-console-producer --broker-list localhost:19092 --topic topic_forward --property schema.registry.url=http://localhost:8081 --property value.schema.id=1 --property auto.register=false --property use.latest.version=false

#value to add
{"my_field1":1,"my_field2":1.1,"my_field3":"text"}


# consume data
kafka-avro-console-consumer --bootstrap-server localhost:19092 --topic topic_forward --property schema.registry.url=http://localhost:8081 --property print.schema.ids=true --from-beginning
```

- Go to control center > topic > Click on schema
- click in the three dots > Compatibility settings > Set to forward
- Evolve schema

- Try to delete a field > it should fail
```json
{
  "type": "record",
  "namespace": "com.mycorp.mynamespace",
  "name": "sampleRecord",
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "name": "my_field1",
      "type": "int",
      "doc": "The int type is a 32-bit signed integer."
    },
    {
      "name": "my_field2",
      "type": "double",
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number."
    }
  ]
}
```
- Try to add an optional field and a mandatory field 
```json
{
  "doc": "Sample schema to help you get started.",
  "fields": [
    {
      "doc": "The int type is a 32-bit signed integer.",
      "name": "my_field1",
      "type": "int"
    },
    {
      "doc": "The double type is a double precision (64-bit) IEEE 754 floating-point number.",
      "name": "my_field2",
      "type": "double"
    },
    {
      "doc": "The string is a unicode character sequence.",
      "name": "my_field3",
      "type": "string"
    },
    {
      "name": "optional_field",
      "default": null,
      "type": ["null", "string"],
      "doc": "This change should be allowed as you are adding a field"
    },
    {
      "name": "mandatory_field",
      "type": "string",
      "doc": "This change should be allowed as you are adding a field"
    }
  ],
  "name": "sampleRecord",
  "namespace": "com.mycorp.mynamespace",
  "type": "record"
}
```
- Save it
- Produce to the topic

```shell

# start producer
kafka-avro-console-producer --broker-list localhost:19092 --topic topic_forward --property schema.registry.url=http://localhost:8081 --property value.schema.id=3 --property auto.register=false --property use.latest.version=false

#value to add
{"my_field1":1,"my_field2":1.1,"my_field3":"text","optional_field":{"string": "text"}, "mandatory_field": "one"}
{"my_field1":1,"my_field2":1.1,"my_field3":"text","optional_field": null, "mandatory_field": "one"}
{"my_field1":1,"my_field2":1.1,"my_field3":"text", "mandatory_field": "one"} <-- fail as the optional_field cannot be guessed (https://forum.confluent.io/t/issues-with-optional-fields-when-using-avro-schema/1628)


# consume data
kafka-avro-console-consumer --bootstrap-server localhost:19092 --topic topic_forward --property schema.registry.url=http://localhost:8081 --property print.schema.ids=true
```

## Clean-up

1. Stop the consumer (control C)
2. Clean the docker cluster `docker-compose down -v`

