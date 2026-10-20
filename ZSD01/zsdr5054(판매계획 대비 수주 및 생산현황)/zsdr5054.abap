*&---------------------------------------------------------------------*
*& Report ZSDR5054
*& 판매계획 대비 수주 및 생산현황
*& 개발클래스 : ZSD01
*& ZSDR0410(월간판매계획) + ZSDR0065(SD수불부) 통합 조회
*& Include 구성은 ZSDR5053 과 같은 규칙, 프로그램명은 ZSDR5054
*&---------------------------------------------------------------------*
REPORT zsdr5054 NO STANDARD PAGE HEADING MESSAGE-ID zsdm.

INCLUDE zsdr5054_t01.   " 데이터 선언부
INCLUDE zsdr5054_s01.   " Selection Screen
INCLUDE zsdr5054_c01.   " ALV 이벤트 클래스
INCLUDE zsdr5054_o01.   " PBO
INCLUDE zsdr5054_i01.   " PAI
INCLUDE zsdr5054_f01.   " Form
INCLUDE zsdr5054_e01.   " 초기화 및 메인 실행부
