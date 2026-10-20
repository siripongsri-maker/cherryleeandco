ALTER TABLE public.homepage_content ADD COLUMN settings jsonb NOT NULL DEFAULT '{}'::jsonb;
GRANT SELECT (settings) ON public.homepage_content TO anon;
COMMENT ON COLUMN public.homepage_content.settings IS 'Validated public website prices, contact destinations, map coordinates, opening times and existing video presentation settings; never staff roles or private data.';