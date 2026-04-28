export const paginationParams = (query: Record<string, unknown>) => {
  const page = Math.max(Number(query.page ?? 1), 1);
  const limit = Math.min(Math.max(Number(query.limit ?? 20), 1), 100);
  return {
    page,
    limit,
    skip: (page - 1) * limit
  };
};

export const paginated = <T>(items: T[], total: number, page: number, limit: number) => ({
  items,
  meta: {
    total,
    page,
    limit,
    pages: Math.ceil(total / limit)
  }
});
