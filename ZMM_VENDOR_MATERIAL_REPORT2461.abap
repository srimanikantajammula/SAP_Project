*&---------------------------------------------------------------------*
*& Report ZMM_VENDOR_MATERIAL_REPORT2461
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMM_VENDOR_MATERIAL_REPORT2461.


TABLES: ekko.
TYPE-POOLS: slis.


TYPES: BEGIN OF ty_output,
         lifnr TYPE ekko-lifnr,
         name1 TYPE lfa1-name1,
         matnr TYPE ekpo-matnr,
         maktx TYPE makt-maktx,
         mtart TYPE mara-mtart,
         menge TYPE ekpo-menge,
         meins TYPE ekpo-meins,
         werks TYPE ekpo-werks,
       END OF ty_output.

DATA: gt_output TYPE TABLE OF ty_output.


DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv.

SELECT-OPTIONS:
  s_ekorg FOR ekko-ekorg OBLIGATORY,
  s_bedat FOR ekko-bedat,
  s_lifnr FOR ekko-lifnr.

INITIALIZATION.

  s_bedat-sign   = 'I'.
  s_bedat-option = 'BT'.
  s_bedat-low    = sy-datum - 90.
  s_bedat-high   = sy-datum.

  APPEND s_bedat.
  AT SELECTION-SCREEN.

  IF s_ekorg[] IS INITIAL.
    MESSAGE 'Purchase Organization is mandatory' TYPE 'E'.
  ENDIF.

  IF s_lifnr[] IS NOT INITIAL.

    SELECT SINGLE lifnr
      FROM lfa1
      WHERE lifnr IN @s_lifnr
      INTO @DATA(lv_lifnr).

    IF sy-subrc <> 0.
      MESSAGE 'Invalid Vendor' TYPE 'E'.
    ENDIF.

  ENDIF.

  IF s_bedat-low IS NOT INITIAL
     AND s_bedat-high IS NOT INITIAL
     AND s_bedat-low > s_bedat-high.

    MESSAGE 'From Date cannot be greater than To Date' TYPE 'E'.

  ENDIF.


CLASS lcl_report DEFINITION.

  PUBLIC SECTION.

    METHODS:
      get_data,
      display_alv.

ENDCLASS.
CLASS lcl_report IMPLEMENTATION.

  METHOD get_data.

    SELECT
        ekko~lifnr,
        lfa1~name1,
        ekpo~matnr,
        makt~maktx,
        mara~mtart,
        ekpo~menge,
        ekpo~meins,
        ekpo~werks
      FROM ekko
      INNER JOIN ekpo
        ON ekko~ebeln = ekpo~ebeln
      INNER JOIN lfa1
        ON ekko~lifnr = lfa1~lifnr
      INNER JOIN mara
        ON ekpo~matnr = mara~matnr
      INNER JOIN makt
        ON ekpo~matnr = makt~matnr
      INTO TABLE @gt_output
      WHERE ekko~ekorg IN @s_ekorg
        AND ekko~bedat IN @s_bedat
        AND ekko~lifnr IN @s_lifnr
        AND makt~spras = @sy-langu.

  ENDMETHOD.
  METHOD display_alv.

    DATA: lo_alv TYPE REF TO cl_salv_table.

    TRY.

        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = gt_output ).

        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->get_columns( )->set_optimize( abap_true ).

        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_salv).

        MESSAGE lx_salv->get_text( ) TYPE 'I'.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
FORM display_function_alv.

  CLEAR gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'LIFNR'.
  gs_fieldcat-seltext_m = 'Vendor Number'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'NAME1'.
  gs_fieldcat-seltext_m = 'Vendor Name'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MATNR'.
  gs_fieldcat-seltext_m = 'Material Number'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MAKTX'.
  gs_fieldcat-seltext_m = 'Material Description'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MTART'.
  gs_fieldcat-seltext_m = 'Material Type'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MENGE'.
  gs_fieldcat-seltext_m = 'Quantity'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MEINS'.
  gs_fieldcat-seltext_m = 'Unit'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'WERKS'.
  gs_fieldcat-seltext_m = 'Plant'.
  APPEND gs_fieldcat TO gt_fieldcat.

  gs_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      is_layout   = gs_layout
      it_fieldcat = gt_fieldcat
    TABLES
      t_outtab    = gt_output
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error while displaying ALV' TYPE 'I'.
  ENDIF.

ENDFORM.
START-OF-SELECTION.

  DATA(lo_report) = NEW lcl_report( ).

  lo_report->get_data( ).

  IF gt_output IS NOT INITIAL.
    PERFORM display_function_alv.
  ELSE.
    MESSAGE 'No data found' TYPE 'I'.
  ENDIF.
