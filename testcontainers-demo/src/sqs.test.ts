import { FlociContainer, StartedFlociContainer } from "@floci/testcontainers";
import {
  SQSClient,
  CreateQueueCommand,
  SendMessageCommand,
  ReceiveMessageCommand,
} from "@aws-sdk/client-sqs";

describe("SQS", () => {
  let floci: StartedFlociContainer;
  let sqs: SQSClient;
  let queueUrl: string;

  beforeAll(async () => {
    floci = await new FlociContainer().start();

    sqs = new SQSClient({
      endpoint: floci.getEndpoint(),
      region: floci.getRegion(),
      credentials: {
        accessKeyId: floci.getAccessKey(),
        secretAccessKey: floci.getSecretKey(),
      },
    });

    const { QueueUrl } = await sqs.send(
      new CreateQueueCommand({ QueueName: "orders" })
    );
    queueUrl = QueueUrl!;
  });

  afterAll(async () => {
    await floci.stop();
  });

  it("sends and receives a message", async () => {
    const message = { event: "order.placed", orderId: "42" };

    await sqs.send(
      new SendMessageCommand({
        QueueUrl: queueUrl,
        MessageBody: JSON.stringify(message),
      })
    );

    const { Messages } = await sqs.send(
      new ReceiveMessageCommand({ QueueUrl: queueUrl, MaxNumberOfMessages: 1 })
    );

    expect(Messages).toHaveLength(1);
    expect(JSON.parse(Messages![0].Body!)).toMatchObject(message);
  });
});
