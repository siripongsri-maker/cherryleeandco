REVOKE SELECT ON public.homepage_content FROM anon;
GRANT SELECT (id, texts, images, version, updated_at) ON public.homepage_content TO anon;