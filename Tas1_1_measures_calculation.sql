USE yappdb
GO
/*
В файле реализован расчет 3 мер для оценки прогнозов количества обращений в поддержку:
Мера 1: количество обращений
Мера 2: Распределение обращений по линиям (доля обращений, приходящихся на 1 линию)
Мера 3. Стандартное отклонение ошибок
В расчетах используется маска для названия расчетных значений, например название m_1_p_1_val означает значение меры 1 для прогноза 1:
m_1 - мера 1
p_1 - прогноз 1
*/

------МЕРА 1. ОБЩЕЕ КОЛИЧЕСТВО ОБРАЩЕНИЙ----

SELECT --приведение к относительным значениям параметров
	MAX(CASE WHEN sub_m_1.data_sample = 'prediction 1'  THEN CAST(abs_res as float) END )  / SUM(sub_m_1.abs_res) as m_1_p_1_val 
	,MAX(CASE WHEN sub_m_1.data_sample = 'prediction 2'  THEN CAST(abs_res as float) END )  / SUM(sub_m_1.abs_res) as m_1_p_2_val 
FROM (
SELECT  --агрегация по количеству обращений в прогнозе 1
	'prediction 1' as data_sample
	,ABS((SELECT SUM(tdata_agr.s_cnt) as cnt FROM fact_incoming_cl as tdata_agr) - SUM(p_cnt)) as abs_res
FROM  prediction_1_cl

UNION

SELECT --агрегация по количеству обращений в прогнозе 2
	'prediction 2' as data_sample
	,ABS((SELECT SUM(tdata_agr.s_cnt) as cnt FROM fact_incoming_cl as tdata_agr) - SUM(p_cnt)) as abs_res
FROM prediction_2_cl ) as sub_m_1
;


----МЕРА 2. РАСПРЕДЕЛЕНИЕ ОБРАЩЕНИЙ ПО ЛИНИЯМ (доля обращений, приходящихся на 1 линию)----

DECLARE @FACT_CNT as float --расчет количества обращений на первую линию (факт)
SET @FACT_CNT  = (SELECT SUM(CASE WHEN fct.qid = '1' THEN CAST(fct.s_cnt as FLOAT) END) / SUM(CAST(fct.s_cnt as FLOAT))
	FROM fact_incoming_cl as fct)
;
SELECT --приведение к относительным значениям параметров
	MAX(CASE WHEN sub_m_2.data_sample = 'prediction 1'  THEN sub_m_2.diff_abs_rates_line_1 END )  / SUM(sub_m_2.diff_abs_rates_line_1) as m_2_p_1_val 
	,MAX(CASE WHEN sub_m_2.data_sample = 'prediction 2'  THEN sub_m_2.diff_abs_rates_line_1 END )  / SUM(sub_m_2.diff_abs_rates_line_1) as m_2_p_2_val 
FROM (
	SELECT 
		'prediction 1' as data_sample --расчет общего количества обращений на первую линию (прогноз 1)
		,ABS(SUM(CASE WHEN tp1.qid = '1' THEN CAST(tp1.p_cnt as FLOAT) END) / SUM(CAST(tp1.p_cnt as FLOAT)) - @FACT_CNT) as diff_abs_rates_line_1 --разница прогноз 1 - факт
	FROM prediction_1_cl as tp1

	UNION

	SELECT 
		'prediction 2' as data_sample --расчет общего количества обращений на первую линию (прогноз 2)
		,ABS(SUM(CASE WHEN tp2.qid = '1' THEN CAST(tp2.p_cnt as FLOAT) END) / SUM(CAST(tp2.p_cnt as FLOAT)) - @FACT_CNT) as diff_abs_rates_line_1 --разница прогноз 2 - факт
	FROM prediction_2_cl as tp2  
) as sub_m_2
;

 ----МЕРА 3. СТАНДАРТНОЕ ОТКЛОНЕНИЕ ОШИБОК---- 
 /*res_predictions_by_hours --вью для расчета ошибок прогнозов по количеству обращений распределенных по часам. */
SELECT --приведение к относительным значениям параметров
	MAX(CASE WHEN sub_m_3.data_sample = 'prediction 1'  THEN sub_m_3.sd_p1 END )  / SUM(sub_m_3.sd_p1) as m_3_p_1_val 
	,MAX(CASE WHEN sub_m_3.data_sample = 'prediction 2'  THEN sub_m_3.sd_p1 END )  / SUM(sub_m_3.sd_p1) as m_3_p_2_val 
FROM (
	SELECT
		'prediction 1' as data_sample
		,SQRT(VAR(res.fact_val - res.p1_val)) as sd_p1 --расчет стандартного отклонения для прогноза 1
	FROM res_predictions_by_hours as res 

	UNION

	SELECT
		'prediction 2' as data_sample
		,SQRT(VAR(res.fact_val - res.p2_val)) as sd_p2 --расчет стандартного отклонения для прогноза 2
	FROM res_predictions_by_hours as res
) as sub_m_3