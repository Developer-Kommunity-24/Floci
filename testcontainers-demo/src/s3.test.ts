import { FlociContainer, StartedFlociContainer } from "@floci/testcontainers";
import {
  S3Client,
  CreateBucketCommand,
  PutObjectCommand,
  GetObjectCommand,
  ListBucketsCommand,
} from "@aws-sdk/client-s3";

describe("S3", () => {
  let floci: StartedFlociContainer;
  let s3: S3Client;

  beforeAll(async () => {
    floci = await new FlociContainer().start();

    s3 = new S3Client({
      endpoint: floci.getEndpoint(),
      region: floci.getRegion(),
      credentials: {
        accessKeyId: floci.getAccessKey(),
        secretAccessKey: floci.getSecretKey(),
      },
      forcePathStyle: true,
    });
  });

  afterAll(async () => {
    await floci.stop();
  });

  it("creates a bucket and lists it", async () => {
    await s3.send(new CreateBucketCommand({ Bucket: "workshop-bucket" }));

    const { Buckets } = await s3.send(new ListBucketsCommand({}));
    expect(Buckets?.some((b) => b.Name === "workshop-bucket")).toBe(true);
  });

  it("puts and gets an object", async () => {
    await s3.send(
      new PutObjectCommand({
        Bucket: "workshop-bucket",
        Key: "hello.txt",
        Body: "Hello, Floci!",
        ContentType: "text/plain",
      })
    );

    const { Body } = await s3.send(
      new GetObjectCommand({ Bucket: "workshop-bucket", Key: "hello.txt" })
    );

    const content = await Body!.transformToString();
    expect(content).toBe("Hello, Floci!");
  });
});
