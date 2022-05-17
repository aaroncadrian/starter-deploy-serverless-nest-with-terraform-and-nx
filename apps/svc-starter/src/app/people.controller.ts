import { Body, Controller, Get, Inject, Param, Post } from '@nestjs/common';
import {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  QueryCommand,
} from '@aws-sdk/client-dynamodb';
import { DYNAMO_TABLE_NAME } from './dynamo-table-name.token';
import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';

@Controller('people')
export class PeopleController {
  constructor(
    private readonly dynamo: DynamoDBClient,
    @Inject(DYNAMO_TABLE_NAME) private readonly tableName: string
  ) {}

  @Get()
  async listPeople() {
    const result = await this.dynamo.send(
      new QueryCommand({
        TableName: this.tableName,
        KeyConditionExpression: '#pk = :pk',
        ExpressionAttributeNames: {
          '#pk': 'pk',
        },
        ExpressionAttributeValues: marshall({
          ':pk': 'PEOPLE',
        }),
      })
    );

    const items = result.Items?.map((item) => unmarshall(item).data) ?? [];

    return {
      items,
    };
  }

  @Get(':personId')
  async getPerson(@Param('personId') personId: string) {
    const result = await this.dynamo.send(
      new GetItemCommand({
        TableName: this.tableName,
        Key: marshall({
          pk: 'PEOPLE',
          sk: personId,
        }),
      })
    );

    const item = result?.Item && unmarshall(result.Item).data;

    return {
      item,
    };
  }

  @Post()
  async createPerson(@Body() body: Record<string, unknown>) {
    const personId = Math.random().toString();

    const item = {
      pk: 'PEOPLE',
      sk: personId,
      data: { ...body, id: personId },
    };

    await this.dynamo.send(
      new PutItemCommand({
        TableName: this.tableName,
        Item: marshall(item),
      })
    );

    return {
      item,
    };
  }
}
