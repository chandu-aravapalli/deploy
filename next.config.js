/** @type {import('next').NextConfig} */
const nextConfig = {
  rewrites: async () => {
    // If deploying to Vercel with FastAPI on AWS
    // Set NEXT_PUBLIC_API_URL in Vercel environment variables
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    
    if (apiUrl) {
      // Use external API (AWS App Runner)
      return [
        {
          source: "/api/:path*",
          destination: `${apiUrl}/api/:path*`,
        },
      ];
    }
    
    // Default: local development or Vercel serverless
    return [
      {
        source: "/api/:path*",
        destination:
          process.env.NODE_ENV === "development"
            ? "http://127.0.0.1:8000/api/:path*"
            : "/api/",
      },
    ];
  },
};

module.exports = nextConfig;

