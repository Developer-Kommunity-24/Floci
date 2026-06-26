export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  const name = event.name ?? "World";
  const timestamp = new Date().toISOString();
  const region = process.env.AWS_DEFAULT_REGION ?? "unknown";

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      timestamp,
      region,
      version: "v2",
    }),
  };
};
