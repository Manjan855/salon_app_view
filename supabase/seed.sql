-- =============================================================================
-- Salon App — Seed data (customer-app release)
--
-- Manually seeded salons across Nepal's 7 provinces, as agreed for this phase
-- (admin panel comes later). Run this AFTER the migrations:
--
--   supabase db reset          # or: supabase db push, then run this in SQL Editor
--
-- Images point at picsum.photos placeholders keyed by salon name so they are
-- stable across re-seeds. Replace with storage://salons/... uploads before
-- launch.
-- =============================================================================

create or replace function public.seed_salon(
  p_name     text,
  p_city     text,
  p_province text,
  p_address  text,
  p_lat      double precision,
  p_lng      double precision,
  p_phone    text,
  p_open     time default '09:00',
  p_close    time default '20:00',
  p_pack     text default 'unisex',        -- gents | unisex | beauty
  p_tags     text[] default '{}'
) returns uuid
language plpgsql
as $$
declare
  v_id       uuid;
  v_img      text;
  v_staff    int;
  v_names    text[] := array[
    'Bikash Tamang','Ramesh Gurung','Sita Lama','Anjali Shrestha','Prakash Rai',
    'Sunita Magar','Rajesh Thapa','Kiran BK','Bishal CK','Sabina Ansari',
    'Nabin Poudel','Menuka Sherpa','Dipak Yadav','Sarita Karki','Pramila Neupane',
    'Sujata Bista','Himal Tamang','Tenzing Sherpa','Gopal Chaudhary','Asha Kumari'
  ];
begin
  select 'https://picsum.photos/seed/' ||
         lower(regexp_replace(p_name, '\s+', '-', 'g')) || '/900/600'
    into v_img;

  insert into public.salons (
    name, description, address, city, province, latitude, longitude,
    phone, image_url, opening_time, closing_time, tags, is_active, is_verified
  ) values (
    p_name,
    case p_pack
      when 'gents'  then 'Men''s grooming studio — precision haircuts, beard sculpting and grooming.'
      when 'beauty' then 'Full-service beauty parlour — bridal makeup, facials, spa and styling.'
      else 'Unisex salon & spa — hair, skin, nails and grooming for everyone.'
    end,
    p_address, p_city, p_province, p_lat, p_lng,
    p_phone, v_img, p_open, p_close,
    case when p_tags[1] is null
         then array[p_pack] || array['walk-ins']
         else p_tags end,
    true, (random() < 0.5)
  ) returning id into v_id;

  -- ---- services by pack (prices in NPR) ------------------------------------
  if p_pack = 'gents' then
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut',            'Professional haircut & styling',                        350::numeric, 30, 'hair'),
      ('Kids Haircut',       'Haircut for children under 12',                         250::numeric, 30, 'hair'),
      ('Beard Trim & Shape', 'Beard trimming, shaping and line-up',                   200::numeric, 20, 'beard'),
      ('Clean Shave',        'Razor shave with hot towel finish',                     150::numeric, 15, 'beard'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                300::numeric, 30, 'massage'),
      ('Hair Colouring',     'Global colour / grey coverage',                        1000::numeric, 90, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing facial for men',                         500::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip and forehead',                      150::numeric, 15, 'skin')
    ) as x(n, d, p, m, c);

  elsif p_pack = 'beauty' then
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut & Blow Dry', 'Haircut, wash and professional blow dry',               600::numeric, 45, 'hair'),
      ('Hair Spa',           'Nourishing keratin hair spa treatment',                 700::numeric, 45, 'spa'),
      ('Hair Colouring',     'Full head global colour',                              1200::numeric, 90, 'hair'),
      ('Hair Highlighting',  'Highlights / streaks with toner',                       1500::numeric, 120,'hair'),
      ('Hair Straightening', 'Smoothening / rebonding treatment',                     3500::numeric,180, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing & glow facial',                          600::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip, forehead, chin',                   150::numeric, 15, 'skin'),
      ('Manicure',           'Nail care, cuticle work and polish',                    400::numeric, 30, 'nails'),
      ('Pedicure',           'Foot care, scrub and polish',                           500::numeric, 40, 'nails'),
      ('Bridal Makeup',      'Complete bridal makeup & hair package',                3500::numeric,180, 'makeup'),
      ('Party Makeup',       'Party / reception makeup',                             1500::numeric, 75, 'makeup'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                350::numeric, 30, 'massage')
    ) as x(n, d, p, m, c);

  else -- unisex
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut',            'Professional unisex haircut & styling',                 400::numeric, 30, 'hair'),
      ('Kids Haircut',       'Haircut for children under 12',                         250::numeric, 30, 'hair'),
      ('Beard Trim & Shape', 'Beard trimming, shaping and line-up',                   200::numeric, 20, 'beard'),
      ('Hair Spa',           'Nourishing keratin hair spa treatment',                 700::numeric, 45, 'spa'),
      ('Hair Colouring',     'Full head global colour',                              1100::numeric, 90, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing & glow facial',                          600::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip and forehead',                      150::numeric, 15, 'skin'),
      ('Manicure',           'Nail care, cuticle work and polish',                    400::numeric, 30, 'nails'),
      ('Pedicure',           'Foot care, scrub and polish',                           500::numeric, 40, 'nails'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                300::numeric, 30, 'massage'),
      ('Bridal Makeup',      'Complete bridal makeup & hair package',                3500::numeric,180, 'makeup')
    ) as x(n, d, p, m, c);
  end if;

  -- ---- stylists ------------------------------------------------------------
  v_staff := case p_pack when 'gents' then 3 when 'beauty' then 4 else 3 end;

  insert into public.staff (salon_id, name, title, specialties)
  select v_id,
         v_names[1 + ((abs(hashtext(v_id::text)) + i) % array_length(v_names, 1))],
         case p_pack
           when 'gents'  then (array['Senior Barber','Beard Specialist','Hair Stylist'])[1 + (i % 3)]
           when 'beauty' then (array['Senior Stylist','Makeup Artist','Skin Specialist','Hair Colourist'])[1 + (i % 4)]
           else (array['Senior Stylist','Hair Colourist','Beauty Therapist'])[1 + (i % 3)]
         end,
         case p_pack
           when 'gents'  then array['hair','beard']
           when 'beauty' then array['hair','skin','makeup','nails']
           else array['hair','skin','nails']
         end
  from generate_series(1, v_staff) i;

  -- ---- working hours: every day, salon hours -------------------------------
  insert into public.staff_availability (staff_id, weekday, start_time, end_time)
  select st.id, d, p_open, p_close
  from public.staff st
  cross join generate_series(0, 6) d
  where st.salon_id = v_id
  on conflict do nothing;

  return v_id;
end;
$$;

-- =============================================================================
-- Salons — 7 provinces, 28 cities/towns
-- =============================================================================
do $$
declare c record;
begin
  for c in
    select * from (values
      -- name, city, province, address, lat, lng, phone, open, close, pack, tags
      ('Style Hub Unisex Salon',   'Kathmandu',  'Bagmati',     'New Baneshwor Chowk, Kathmandu 44600',      27.6930, 85.3310, '+977-1-4101234', '09:00', '20:00', 'unisex', array['walk-ins','parking']),
      ('Kathmandu Grooming Co.',   'Kathmandu',  'Bagmati',     'Jhamsikhel Road, Lalitpur 44600',            27.6780, 85.3150, '+977-1-5523344', '10:00', '21:00', 'gents',  array['mens-only','beard']),
      ('Aakriti Beauty Parlour',   'Lalitpur',   'Bagmati',     'Pulchowk Main Road, Lalitpur',              27.6740, 85.3200, '+977-1-5534455', '09:30', '19:30', 'beauty', array['bridal','women-only']),
      ('Bhaktapur Hair Studio',    'Bhaktapur',  'Bagmati',     'Durbar Square Road, Bhaktapur 44800',        27.6710, 85.4290, '+977-1-6215566', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Hetauda Style Point',      'Hetauda',    'Bagmati',     'Jamal Road, Hetauda 45300',                 27.4240, 85.0320, '+977-1-6321177', '09:00', '19:00', 'gents',  array['mens-only']),
      ('Nagarkot Spa & Salon',     'Nagarkot',   'Bagmati',     'Hill Road, Nagarkot 44610',                 27.7150, 85.5230, '+977-1-6680099', '10:00', '18:00', 'beauty', array['spa','resort']),
      ('Bharatpur Beauty Care',    'Bharatpur',  'Bagmati',     'Station Chowk, Bharatpur 44200',            27.6760, 84.4350, '+977-56-520111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Pokhara Hair Lounge',      'Pokhara',    'Gandaki',     'Lakeside Road, Pokhara 33700',              28.2090, 83.9560, '+977-61-460111', '09:00', '21:00', 'unisex', array['tourist-area','walk-ins']),
      ('Annapurna Grooming Bar',   'Pokhara',    'Gandaki',     'Mahendrapul, Pokhara 33700',                28.2260, 83.9690, '+977-61-462222', '10:00', '20:00', 'gents',  array['mens-only','beard']),
      ('Gorkha Style House',       'Gorkha',     'Gandaki',     'Arubari Bazaar, Gorkha 34000',              28.0000, 84.6330, '+977-64-412233', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Bandipur Beauty Salon',    'Bandipur',   'Gandaki',     'Main Street, Bandipur 34500',               27.9390, 84.4110, '+977-65-690111', '10:00', '18:00', 'beauty', array['heritage']),
      ('Besisahar Hair & Beauty',  'Besisahar',  'Gandaki',     'Lamjung Bazaar, Beshisahar 44800',          28.2360, 84.3830, '+977-66-520111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Damauli Salon & Spa',      'Damauli',    'Gandaki',     'Highway Chowk, Damauli 44200',              27.9830, 84.5830, '+977-56-412233', '09:00', '19:00', 'beauty', array['spa']),
      ('Butwal Grooming Studio',   'Butwal',     'Lumbini',     'Traffic Chowk, Butwal 32900',               27.7000, 83.4480, '+977-71-545111', '09:00', '20:00', 'gents',  array['mens-only']),
      ('Bhairahawa Beauty Lounge', 'Bhairahawa', 'Lumbini',     'Siddhartha Marg, Bhairahawa 32900',         27.5000, 83.4500, '+977-71-522333', '09:30', '19:30', 'beauty', array['bridal']),
      ('Tansen Style Parlour',     'Tansen',     'Lumbini',     'Dado Bazaar, Tansen 32500',                 27.8670, 83.5500, '+977-75-521111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Tulsipur Hair Creations',  'Tulsipur',   'Lumbini',     'Rajmarg Chowk, Tulsipur 32900',             28.1330, 82.3000, '+977-82-521111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Nepalgunj Hair & Beauty',  'Nepalgunj',  'Lumbini',     'Mahendra Chowk, Nepalgunj 32900',           28.0500, 81.6170, '+977-81-525111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Biratnagar Barber Club',   'Biratnagar', 'Koshi',       'Main Road, Biratnagar 56600',               26.4520, 87.2640, '+977-21-470111', '09:00', '20:00', 'gents',  array['mens-only','beard']),
      ('Dharan Style Corner',      'Dharan',     'Koshi',       'Bhanu Chowk, Dharan 56700',                 26.8100, 87.2830, '+977-25-520111', '09:00', '20:00', 'unisex', array['walk-ins']),
      ('Itahari Beauty Zone',      'Itahari',    'Koshi',       'Dharan Road, Itahari 56705',                26.6660, 87.2830, '+977-25-580111', '09:30', '19:30', 'beauty', array['bridal']),
      ('Damak Hair Studio',        'Damak',      'Koshi',       'Birat Road, Damak 56705',                   26.6640, 87.3510, '+977-26-590111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Ilam Tea Garden Salon',    'Ilam',       'Koshi',       'Ilam Bazaar, Ilam 57300',                   26.9090, 87.9300, '+977-27-520111', '09:00', '18:00', 'beauty', array['hill-station']),
      ('Birgunj Grooming House',   'Birgunj',    'Madhesh',     'Adarsh Nagar, Birgunj 44300',               27.0360, 84.8770, '+977-51-412222', '09:00', '20:00', 'gents',  array['mens-only']),
      ('Janakpur Beauty Court',    'Janakpur',   'Madhesh',     'Campus Road, Janakpur 45600',               26.7280, 85.9250, '+977-41-522111', '09:00', '20:00', 'beauty', array['bridal','saree-styling']),
      ('Rajbiraj Style Hub',       'Rajbiraj',   'Madhesh',     'Ghantaghar Road, Rajbiraj 56000',           26.5400, 86.7470, '+977-45-572111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Birendranagar Salon',      'Birendranagar','Karnali',   'Surkhet Bazaar, Birendranagar 21900',       28.6000, 82.0700, '+977-84-412111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Dhangadhi Hair & Beauty',  'Dhangadhi',  'Sudurpashchim','Godawari Road, Dhangadhi 57500',          28.7000, 80.6000, '+977-91-522111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Bhimdatta Grooming Point', 'Bhimdatta',  'Sudurpashchim','Mahakali Chowk, Bhimdatta 57500',         28.9640, 80.3320, '+977-91-412111', '09:00', '19:00', 'gents',  array['mens-only'])
    ) as t(name, city, province, address, lat, lng, phone, open, close, pack, tags)
  loop
    perform public.seed_salon(c.name, c.city, c.province, c.address, c.lat, c.lng,
                              c.phone, c.open::time, c.close::time, c.pack, c.tags);
  end loop;
end;
$$;

-- =============================================================================
-- Coupons — backs the promocodes sheet in profile_screen.dart
-- =============================================================================
insert into public.coupons (code, discount_percent, max_discount, valid_to, max_uses, is_active) values
  ('NEPAL10',  10, 300,  now() + interval '1 year', 10000, true),
  ('FIRST20',  20, 500,  now() + interval '1 year',  5000, true),
  ('FESTIVE25',25, 750,  now() + interval '6 months',2000, true),
  ('WELCOME50',50,1000,  now() + interval '3 months',1000, true)
on conflict (code) do nothing;

-- =============================================================================
-- Cleanup — remove the seeding helper from the schema
-- =============================================================================
drop function public.seed_salon(text, text, text, text, double precision,
                                 double precision, text, time, time, text, text[]);

-- Verification
select city, province, count(*) as salons, sum((select count(*) from public.services s where s.salon_id = salons.id)) as services
from public.salons
group by city, province
order by province, city;
