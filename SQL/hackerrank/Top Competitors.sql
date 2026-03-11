SELECT
    smcdh.hacker_id,
    smcdh.name
  from (
    select
        smcd.hacker_id,
        h.name,
        sum(smcd.full_yn) as total_full_yn
    from (
        SELECT
            smc.*,
            d.score as max_score,
            case when smc.score = d.score then 1 else 0 end as full_yn
        from (
            SELECT
            sm.hacker_id,
            sm.challenge_id,
            sm.score,
            c.difficulty_level
            from (
                SELECT
                hacker_id,
                challenge_id,
                max(score) as score
                from submissions
                group by 1, 2
            ) sm
            left join challenges c
              on sm.challenge_id = c.challenge_id
        ) smc
        left join difficulty d
            on smc.difficulty_level = d.difficulty_level
    ) smcd
    left join hackers h
        on smcd.hacker_id = h.hacker_id
    group by 1, 2
    having sum(smcd.full_yn) > 1
  ) smcdh
order by smcdh.total_full_yn desc, smcdh.hacker_id


/* GPT가 제안해준 방식 */
select
    s.hacker_id,
    h.name
from (
    select
        hacker_id,
        challenge_id,
        max(score) as score
    from submissions
    group by hacker_id, challenge_id
) s
join challenges c
    on s.challenge_id = c.challenge_id
join difficulty d
    on c.difficulty_level = d.difficulty_level
join hackers h
    on s.hacker_id = h.hacker_id
where s.score = d.score
group by s.hacker_id, h.name
having count(*) > 1
order by count(*) desc, s.hacker_id;