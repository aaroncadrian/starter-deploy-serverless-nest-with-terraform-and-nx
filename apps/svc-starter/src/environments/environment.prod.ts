export const environment = {
  production: true,

  dynamoDb: {
    tableName: process.env.DYNAMO_TABLE_NAME,
  },
};
