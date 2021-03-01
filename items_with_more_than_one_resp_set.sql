/* this select unique response_sets per item
 * which can then be used to count the occurrences and then select those that need looking into 
 */
with candidate_items as 
	( -- find the unique/distinct response-groups per item
	with unique_resp_set_all_versions as
		(select distinct cv.crf_id, ifm.item_id, rs.options_values, rs.options_text from 
		item_form_metadata ifm 
		left join response_set rs on ifm.response_set_id=rs.response_set_id
		left join crf_version cv on ifm.crf_version_id=cv.crf_version_id
		-- only look at radio's, select, and multi's
		where rs.response_type_id in (3, 5, 6, 7)
		order by ifm.item_id )
	-- count the number of response-groups per item
	select urs.crf_id, urs.item_id, count(urs.item_id) as tot_resp_set 
	from unique_resp_set_all_versions urs
	group by urs.crf_id, urs.item_id
	-- and only inspect those that have more than one response-group
	having count(urs.item_id) > 1
	)
	-- find crf-name and item-name to that
	select c.name as crf_name, ci.item_id, i.name as item_name, i.oc_oid as item_oid, check_for_faulty_response_set(ci.item_id)
	from candidate_items ci
	inner join crf c on c.crf_id=ci.crf_id
	inner join item i on i.item_id=ci.item_id
	where check_for_faulty_response_set(ci.item_id) <> ''
	;
	