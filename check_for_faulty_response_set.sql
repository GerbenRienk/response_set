-- DROP FUNCTION public.check_for_faulty_response_set(integer);

CREATE OR REPLACE FUNCTION public.check_for_faulty_response_set(this_item_id integer)
/* Function that takes the item_id as parameter.
 * The function takes all response_sets associated with it in descending order,
 * to check if every version 'fits' into the last one.
 * This is done by checking if the options as value and as text are part of the last version, using 'position'
 * and as a consequence, this means that changes in the order, or additional spaces are also listed as differences.
 */
RETURNS text AS
$BODY$
declare 
	check_report text default ''; -- this variable will hold our conclusion about the response_sets for this item
	last_options_values text;	  -- this var will hold the values of the last/most recent response-set
	last_options_text text;		  -- this var will hold the text of the last/most recent response-set
	rec_response_set   record;
	one_or_more_errors boolean;   -- boolean to indicate that we have versions of response-sets that can be a problem
	cursor_response_set cursor 
		for select ifm.item_id, cv.name as crf_version_name, rs.options_values, rs.options_text
		from item_form_metadata ifm
		inner join response_set rs on rs.response_set_id=ifm.response_set_id
		inner join crf_version cv on cv.crf_version_id=ifm.crf_version_id
		where ifm.item_id=this_item_id
		order by rs.version_id desc
		;
begin
	-- by default assume no errors
	one_or_more_errors := false;
	-- open the cursor
	open cursor_response_set;
	-- before we start looping, fetch the latest version, which is in the first row
	fetch cursor_response_set into rec_response_set;
	last_options_values := rec_response_set.options_values;
	last_options_text := rec_response_set.options_text;	
	check_report := concat('last values-text: (', rec_response_set.crf_version_name, ') ', last_options_values, ' = "', last_options_text, '"');
	loop
		 -- fetch next row
		 fetch cursor_response_set into rec_response_set;
		 -- exit when no more row to fetch
		 exit when not found;
 
		-- build the output
		-- first check if we have a difference in values, or in text
     
		if position(trim(rec_response_set.options_values) in trim(last_options_values)) = 0  or position(trim(rec_response_set.options_text) in trim(last_options_text)) = 0 then        
			check_report := concat(check_report, ' vs. (', rec_response_set.crf_version_name, ') ', rec_response_set.options_values, ' = "', rec_response_set.options_text, '"');
			one_or_more_errors := true;
		else
			-- we're good, because both the values and the text can be found in the latest version
		end if;
   end loop;
  
   -- close the cursor
   close cursor_response_set;
   -- if we have no errors, then return empty string
   if not one_or_more_errors then check_report := ''; end if;
   return check_report;
end; $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
ALTER FUNCTION public.check_for_faulty_response_set(integer)
OWNER TO postgres;