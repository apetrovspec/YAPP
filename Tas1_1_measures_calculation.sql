USE yappdb
GO
/*
� ����� ���������� ������ 3 ��� ��� ������ ��������� ���������� ��������� � ���������:
���� 1: ���������� ���������
���� 2: ������������� ��������� �� ������ (���� ���������, ������������ �� 1 �����)
���� 3. ����������� ���������� ������
� �������� ������������ ����� ��� �������� ��������� ��������, �������� �������� m_1_p_1_val �������� �������� ���� 1 ��� �������� 1:
m_1 - ���� 1
p_1 - ������� 1
*/

------���� 1. ����� ���������� ���������----

SELECT --���������� � ������������� ��������� ����������
	MAX(CASE WHEN sub_m_1.data_sample = 'prediction 1'  THEN CAST(abs_res as float) END )  / SUM(sub_m_1.abs_res) as m_1_p_1_val 
	,MAX(CASE WHEN sub_m_1.data_sample = 'prediction 2'  THEN CAST(abs_res as float) END )  / SUM(sub_m_1.abs_res) as m_1_p_2_val 
FROM (
SELECT  --��������� �� ���������� ��������� � �������� 1
	'prediction 1' as data_sample
	,ABS((SELECT SUM(tdata_agr.s_cnt) as cnt FROM fact_incoming_cl as tdata_agr) - SUM(p_cnt)) as abs_res
FROM  prediction_1_cl

UNION

SELECT --��������� �� ���������� ��������� � �������� 2
	'prediction 2' as data_sample
	,ABS((SELECT SUM(tdata_agr.s_cnt) as cnt FROM fact_incoming_cl as tdata_agr) - SUM(p_cnt)) as abs_res
FROM prediction_2_cl ) as sub_m_1
;


----���� 2. ������������� ��������� �� ������ (���� ���������, ������������ �� 1 �����)----

DECLARE @FACT_CNT as float --������ ���������� ��������� �� ������ ����� (����)
SET @FACT_CNT  = (SELECT SUM(CASE WHEN fct.qid = '1' THEN CAST(fct.s_cnt as FLOAT) END) / SUM(CAST(fct.s_cnt as FLOAT))
	FROM fact_incoming_cl as fct)
;
SELECT --���������� � ������������� ��������� ����������
	MAX(CASE WHEN sub_m_2.data_sample = 'prediction 1'  THEN sub_m_2.diff_abs_rates_line_1 END )  / SUM(sub_m_2.diff_abs_rates_line_1) as m_2_p_1_val 
	,MAX(CASE WHEN sub_m_2.data_sample = 'prediction 2'  THEN sub_m_2.diff_abs_rates_line_1 END )  / SUM(sub_m_2.diff_abs_rates_line_1) as m_2_p_2_val 
FROM (
	SELECT 
		'prediction 1' as data_sample --������ ������ ���������� ��������� �� ������ ����� (������� 1)
		,ABS(SUM(CASE WHEN tp1.qid = '1' THEN CAST(tp1.p_cnt as FLOAT) END) / SUM(CAST(tp1.p_cnt as FLOAT)) - @FACT_CNT) as diff_abs_rates_line_1 --������� ������� 1 - ����
	FROM prediction_1_cl as tp1

	UNION

	SELECT 
		'prediction 2' as data_sample --������ ������ ���������� ��������� �� ������ ����� (������� 2)
		,ABS(SUM(CASE WHEN tp2.qid = '1' THEN CAST(tp2.p_cnt as FLOAT) END) / SUM(CAST(tp2.p_cnt as FLOAT)) - @FACT_CNT) as diff_abs_rates_line_1 --������� ������� 2 - ����
	FROM prediction_2_cl as tp2  
) as sub_m_2
;

 ----���� 3. ����������� ���������� ������---- 
 /*res_predictions_by_hours --��� ��� ������� ������ ��������� �� ���������� ��������� �������������� �� �����. */
SELECT --���������� � ������������� ��������� ����������
	MAX(CASE WHEN sub_m_3.data_sample = 'prediction 1'  THEN sub_m_3.sd_p1 END )  / SUM(sub_m_3.sd_p1) as m_3_p_1_val 
	,MAX(CASE WHEN sub_m_3.data_sample = 'prediction 2'  THEN sub_m_3.sd_p1 END )  / SUM(sub_m_3.sd_p1) as m_3_p_2_val 
FROM (
	SELECT
		'prediction 1' as data_sample
		,SQRT(VAR(res.fact_val - res.p1_val)) as sd_p1 --������ ������������ ���������� ��� �������� 1
	FROM res_predictions_by_hours as res 

	UNION

	SELECT
		'prediction 2' as data_sample
		,SQRT(VAR(res.fact_val - res.p2_val)) as sd_p2 --������ ������������ ���������� ��� �������� 2
	FROM res_predictions_by_hours as res
) as sub_m_3