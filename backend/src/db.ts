import postgres from "postgres";

const sql = postgres(process.env.DATABASE_URL!, {
  prepare: false,
  max: 4,
});

export default sql;
