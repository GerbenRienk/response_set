/* this select lists all the response_sets in use
 * it is included to get an idea of what we're talking about
 * 
 * 
 */
with resp_set_all_versions as(
select c.name, cv.crf_id, ifm.crf_version_id, ifm.item_id, rs.* from 
  item_form_metadata ifm 
  left join response_set rs on ifm.response_set_id=rs.response_set_id
  left join crf_version cv on ifm.crf_version_id=cv.crf_version_id
  left join crf c on c.crf_id=cv.crf_id
order by ifm.item_id, c.crf_id, ifm.crf_version_id)

select * from resp_set_all_versions;
	