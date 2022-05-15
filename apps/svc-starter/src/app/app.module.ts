import { Module } from '@nestjs/common';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DYNAMO_TABLE_NAME } from './dynamo-table-name.token';
import { environment } from '../environments/environment';
import { PeopleController } from './people.controller';

@Module({
  imports: [],
  controllers: [AppController, PeopleController],
  providers: [
    AppService,
    {
      provide: DynamoDBClient,
      useValue: new DynamoDBClient({}),
    },
    {
      provide: DYNAMO_TABLE_NAME,
      useValue: environment.dynamoDb.tableName,
    },
  ],
})
export class AppModule {}
