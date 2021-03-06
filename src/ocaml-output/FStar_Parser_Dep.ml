open Prims
type verify_mode =
  | VerifyAll 
  | VerifyUserList 
  | VerifyFigureItOut 
let uu___is_VerifyAll : verify_mode -> Prims.bool =
  fun projectee  ->
    match projectee with | VerifyAll  -> true | uu____4 -> false
  
let uu___is_VerifyUserList : verify_mode -> Prims.bool =
  fun projectee  ->
    match projectee with | VerifyUserList  -> true | uu____8 -> false
  
let uu___is_VerifyFigureItOut : verify_mode -> Prims.bool =
  fun projectee  ->
    match projectee with | VerifyFigureItOut  -> true | uu____12 -> false
  
type map = (Prims.string option * Prims.string option) FStar_Util.smap
type color =
  | White 
  | Gray 
  | Black 
let uu___is_White : color -> Prims.bool =
  fun projectee  -> match projectee with | White  -> true | uu____21 -> false 
let uu___is_Gray : color -> Prims.bool =
  fun projectee  -> match projectee with | Gray  -> true | uu____25 -> false 
let uu___is_Black : color -> Prims.bool =
  fun projectee  -> match projectee with | Black  -> true | uu____29 -> false 
let check_and_strip_suffix : Prims.string -> Prims.string option =
  fun f  ->
    let suffixes = [".fsti"; ".fst"; ".fsi"; ".fs"]  in
    let matches =
      FStar_List.map
        (fun ext  ->
           let lext = FStar_String.length ext  in
           let l = FStar_String.length f  in
           let uu____46 =
             (l > lext) &&
               (let uu____52 = FStar_String.substring f (l - lext) lext  in
                uu____52 = ext)
              in
           if uu____46
           then
             let uu____61 =
               FStar_String.substring f (Prims.parse_int "0") (l - lext)  in
             Some uu____61
           else None) suffixes
       in
    let uu____68 = FStar_List.filter FStar_Util.is_some matches  in
    match uu____68 with | (Some m)::uu____74 -> Some m | uu____78 -> None
  
let is_interface : Prims.string -> Prims.bool =
  fun f  ->
    let uu____84 =
      FStar_String.get f ((FStar_String.length f) - (Prims.parse_int "1"))
       in
    uu____84 = 'i'
  
let is_implementation : Prims.string -> Prims.bool =
  fun f  -> let uu____91 = is_interface f  in Prims.op_Negation uu____91 
let list_of_option uu___84_100 =
  match uu___84_100 with | Some x -> [x] | None  -> [] 
let list_of_pair uu____114 =
  match uu____114 with
  | (intf,impl) ->
      FStar_List.append (list_of_option intf) (list_of_option impl)
  
let lowercase_module_name : Prims.string -> Prims.string =
  fun f  ->
    let uu____128 =
      let uu____130 = FStar_Util.basename f  in
      check_and_strip_suffix uu____130  in
    match uu____128 with
    | Some longname -> FStar_String.lowercase longname
    | None  ->
        let uu____132 =
          let uu____133 = FStar_Util.format1 "not a valid FStar file: %s\n" f
             in
          FStar_Errors.Err uu____133  in
        raise uu____132
  
let build_map :
  Prims.string Prims.list ->
    (Prims.string option * Prims.string option) FStar_Util.smap
  =
  fun filenames  ->
    let include_directories = FStar_Options.include_path ()  in
    let include_directories1 =
      FStar_List.map FStar_Util.normalize_file_path include_directories  in
    let include_directories2 = FStar_List.unique include_directories1  in
    let cwd =
      let uu____146 = FStar_Util.getcwd ()  in
      FStar_Util.normalize_file_path uu____146  in
    let map1 = FStar_Util.smap_create (Prims.parse_int "41")  in
    let add_entry key full_path =
      let uu____164 = FStar_Util.smap_try_find map1 key  in
      match uu____164 with
      | Some (intf,impl) ->
          let uu____184 = is_interface full_path  in
          if uu____184
          then FStar_Util.smap_add map1 key ((Some full_path), impl)
          else FStar_Util.smap_add map1 key (intf, (Some full_path))
      | None  ->
          let uu____202 = is_interface full_path  in
          if uu____202
          then FStar_Util.smap_add map1 key ((Some full_path), None)
          else FStar_Util.smap_add map1 key (None, (Some full_path))
       in
    FStar_List.iter
      (fun d  ->
         if FStar_Util.file_exists d
         then
           let files = FStar_Util.readdir d  in
           FStar_List.iter
             (fun f  ->
                let f1 = FStar_Util.basename f  in
                let uu____222 = check_and_strip_suffix f1  in
                match uu____222 with
                | Some longname ->
                    let full_path =
                      if d = cwd then f1 else FStar_Util.join_paths d f1  in
                    let key = FStar_String.lowercase longname  in
                    add_entry key full_path
                | None  -> ()) files
         else
           (let uu____229 =
              let uu____230 =
                FStar_Util.format1 "not a valid include directory: %s\n" d
                 in
              FStar_Errors.Err uu____230  in
            raise uu____229)) include_directories2;
    FStar_List.iter
      (fun f  ->
         let uu____233 = lowercase_module_name f  in add_entry uu____233 f)
      filenames;
    map1
  
let enter_namespace : map -> map -> Prims.string -> Prims.bool =
  fun original_map  ->
    fun working_map  ->
      fun prefix1  ->
        let found = FStar_Util.mk_ref false  in
        let prefix2 = Prims.strcat prefix1 "."  in
        (let uu____248 =
           let uu____250 = FStar_Util.smap_keys original_map  in
           FStar_List.unique uu____250  in
         FStar_List.iter
           (fun k  ->
              if FStar_Util.starts_with k prefix2
              then
                let suffix =
                  FStar_String.substring k (FStar_String.length prefix2)
                    ((FStar_String.length k) - (FStar_String.length prefix2))
                   in
                let filename =
                  let uu____270 = FStar_Util.smap_try_find original_map k  in
                  FStar_Util.must uu____270  in
                (FStar_Util.smap_add working_map suffix filename;
                 FStar_ST.write found true)
              else ()) uu____248);
        FStar_ST.read found
  
let string_of_lid : FStar_Ident.lident -> Prims.bool -> Prims.string =
  fun l  ->
    fun last1  ->
      let suffix =
        if last1 then [(l.FStar_Ident.ident).FStar_Ident.idText] else []  in
      let names =
        let uu____306 =
          FStar_List.map (fun x  -> x.FStar_Ident.idText) l.FStar_Ident.ns
           in
        FStar_List.append uu____306 suffix  in
      FStar_String.concat "." names
  
let lowercase_join_longident :
  FStar_Ident.lident -> Prims.bool -> Prims.string =
  fun l  ->
    fun last1  ->
      let uu____315 = string_of_lid l last1  in
      FStar_String.lowercase uu____315
  
let check_module_declaration_against_filename :
  FStar_Ident.lident -> Prims.string -> Prims.unit =
  fun lid  ->
    fun filename  ->
      let k' = lowercase_join_longident lid true  in
      let uu____323 =
        let uu____324 =
          let uu____325 =
            let uu____326 =
              let uu____328 = FStar_Util.basename filename  in
              check_and_strip_suffix uu____328  in
            FStar_Util.must uu____326  in
          FStar_String.lowercase uu____325  in
        uu____324 <> k'  in
      if uu____323
      then
        let uu____329 = string_of_lid lid true  in
        FStar_Util.print2_warning
          "Warning: the module declaration \"module %s\" found in file %s does not match its filename. Dependencies will be incorrect.\n"
          uu____329 filename
      else ()
  
exception Exit 
let uu___is_Exit : Prims.exn -> Prims.bool =
  fun projectee  -> match projectee with | Exit  -> true | uu____334 -> false 
let collect_one :
  (Prims.string * Prims.bool FStar_ST.ref) Prims.list ->
    verify_mode ->
      Prims.bool -> map -> Prims.string -> Prims.string Prims.list
  =
  fun verify_flags  ->
    fun verify_mode  ->
      fun is_user_provided_filename  ->
        fun original_map  ->
          fun filename  ->
            let deps = FStar_Util.mk_ref []  in
            let add_dep d =
              let uu____369 =
                let uu____370 =
                  let uu____371 = FStar_ST.read deps  in
                  FStar_List.existsML (fun d'  -> d' = d) uu____371  in
                Prims.op_Negation uu____370  in
              if uu____369
              then
                let uu____377 =
                  let uu____379 = FStar_ST.read deps  in d :: uu____379  in
                FStar_ST.write deps uu____377
              else ()  in
            let working_map = FStar_Util.smap_copy original_map  in
            let record_open let_open lid =
              let key = lowercase_join_longident lid true  in
              let uu____406 = FStar_Util.smap_try_find working_map key  in
              match uu____406 with
              | Some pair ->
                  FStar_List.iter
                    (fun f  ->
                       let uu____426 = lowercase_module_name f  in
                       add_dep uu____426) (list_of_pair pair)
              | None  ->
                  let r = enter_namespace original_map working_map key  in
                  if Prims.op_Negation r
                  then
                    (if let_open
                     then
                       raise
                         (FStar_Errors.Err
                            "let-open only supported for modules, not namespaces")
                     else
                       (let uu____433 = string_of_lid lid true  in
                        FStar_Util.print1_warning
                          "Warning: no modules in namespace %s and no file with that name either\n"
                          uu____433))
                  else ()
               in
            let record_module_alias ident lid =
              let key = FStar_String.lowercase (FStar_Ident.text_of_id ident)
                 in
              let alias = lowercase_join_longident lid true  in
              let uu____444 = FStar_Util.smap_try_find original_map alias  in
              match uu____444 with
              | Some deps_of_aliased_module ->
                  FStar_Util.smap_add working_map key deps_of_aliased_module
              | None  ->
                  let uu____471 =
                    let uu____472 =
                      FStar_Util.format1
                        "module not found in search path: %s\n" alias
                       in
                    FStar_Errors.Err uu____472  in
                  raise uu____471
               in
            let record_lid lid =
              let try_key key =
                let uu____481 = FStar_Util.smap_try_find working_map key  in
                match uu____481 with
                | Some pair ->
                    FStar_List.iter
                      (fun f  ->
                         let uu____501 = lowercase_module_name f  in
                         add_dep uu____501) (list_of_pair pair)
                | None  ->
                    let uu____506 =
                      ((FStar_List.length lid.FStar_Ident.ns) >
                         (Prims.parse_int "0"))
                        && (FStar_Options.debug_any ())
                       in
                    if uu____506
                    then
                      let uu____510 =
                        FStar_Range.string_of_range
                          (FStar_Ident.range_of_lid lid)
                         in
                      let uu____511 = string_of_lid lid false  in
                      FStar_Util.print2_warning
                        "%s (Warning): unbound module reference %s\n"
                        uu____510 uu____511
                    else ()
                 in
              let uu____514 = lowercase_join_longident lid false  in
              try_key uu____514  in
            let auto_open =
              let uu____517 =
                let uu____518 = FStar_Util.basename filename  in
                let uu____519 = FStar_Options.prims_basename ()  in
                uu____518 = uu____519  in
              if uu____517
              then []
              else
                (let l =
                   [FStar_Parser_Const.fstar_ns_lid;
                   FStar_Parser_Const.prims_lid]  in
                 let uu____524 =
                   let uu____525 = FStar_Util.basename filename  in
                   let uu____526 = FStar_Options.pervasives_basename ()  in
                   uu____525 = uu____526  in
                 if uu____524
                 then l
                 else FStar_List.append l [FStar_Parser_Const.pervasives_lid])
               in
            FStar_List.iter (record_open false) auto_open;
            (let num_of_toplevelmods =
               FStar_Util.mk_ref (Prims.parse_int "0")  in
             let rec collect_fragment uu___85_601 =
               match uu___85_601 with
               | FStar_Util.Inl file -> collect_file file
               | FStar_Util.Inr decls -> collect_decls decls
             
             and collect_file uu___86_614 =
               match uu___86_614 with
               | modul::[] -> collect_module modul
               | modules ->
                   (FStar_Util.print1_warning
                      "Warning: file %s does not respect the one module per file convention\n"
                      filename;
                    FStar_List.iter collect_module modules)
             
             and collect_module uu___87_620 =
               match uu___87_620 with
               | FStar_Parser_AST.Module (lid,decls) ->
                   (check_module_declaration_against_filename lid filename;
                    (match verify_mode with
                     | VerifyAll  ->
                         let uu____627 = string_of_lid lid true  in
                         FStar_Options.add_verify_module uu____627
                     | VerifyFigureItOut  ->
                         if is_user_provided_filename
                         then
                           let uu____628 = string_of_lid lid true  in
                           FStar_Options.add_verify_module uu____628
                         else ()
                     | VerifyUserList  ->
                         FStar_List.iter
                           (fun uu____633  ->
                              match uu____633 with
                              | (m,r) ->
                                  let uu____641 =
                                    let uu____642 =
                                      let uu____643 = string_of_lid lid true
                                         in
                                      FStar_String.lowercase uu____643  in
                                    (FStar_String.lowercase m) = uu____642
                                     in
                                  if uu____641
                                  then FStar_ST.write r true
                                  else ()) verify_flags);
                    collect_decls decls)
               | FStar_Parser_AST.Interface (lid,decls,uu____649) ->
                   (check_module_declaration_against_filename lid filename;
                    (match verify_mode with
                     | VerifyAll  ->
                         let uu____654 = string_of_lid lid true  in
                         FStar_Options.add_verify_module uu____654
                     | VerifyFigureItOut  ->
                         if is_user_provided_filename
                         then
                           let uu____655 = string_of_lid lid true  in
                           FStar_Options.add_verify_module uu____655
                         else ()
                     | VerifyUserList  ->
                         FStar_List.iter
                           (fun uu____660  ->
                              match uu____660 with
                              | (m,r) ->
                                  let uu____668 =
                                    let uu____669 =
                                      let uu____670 = string_of_lid lid true
                                         in
                                      FStar_String.lowercase uu____670  in
                                    (FStar_String.lowercase m) = uu____669
                                     in
                                  if uu____668
                                  then FStar_ST.write r true
                                  else ()) verify_flags);
                    collect_decls decls)
             
             and collect_decls decls =
               FStar_List.iter
                 (fun x  ->
                    collect_decl x.FStar_Parser_AST.d;
                    FStar_List.iter collect_term x.FStar_Parser_AST.attrs)
                 decls
             
             and collect_decl uu___88_678 =
               match uu___88_678 with
               | FStar_Parser_AST.Include lid -> record_open false lid
               | FStar_Parser_AST.Open lid -> record_open false lid
               | FStar_Parser_AST.ModuleAbbrev (ident,lid) ->
                   ((let uu____684 = lowercase_join_longident lid true  in
                     add_dep uu____684);
                    record_module_alias ident lid)
               | FStar_Parser_AST.TopLevelLet (uu____685,patterms) ->
                   FStar_List.iter
                     (fun uu____695  ->
                        match uu____695 with
                        | (pat,t) -> (collect_pattern pat; collect_term t))
                     patterms
               | FStar_Parser_AST.Main t -> collect_term t
               | FStar_Parser_AST.Assume (uu____702,t) -> collect_term t
               | FStar_Parser_AST.SubEffect
                   { FStar_Parser_AST.msource = uu____704;
                     FStar_Parser_AST.mdest = uu____705;
                     FStar_Parser_AST.lift_op =
                       FStar_Parser_AST.NonReifiableLift t;_}
                   -> collect_term t
               | FStar_Parser_AST.SubEffect
                   { FStar_Parser_AST.msource = uu____707;
                     FStar_Parser_AST.mdest = uu____708;
                     FStar_Parser_AST.lift_op = FStar_Parser_AST.LiftForFree
                       t;_}
                   -> collect_term t
               | FStar_Parser_AST.Val (uu____710,t) -> collect_term t
               | FStar_Parser_AST.SubEffect
                   { FStar_Parser_AST.msource = uu____712;
                     FStar_Parser_AST.mdest = uu____713;
                     FStar_Parser_AST.lift_op =
                       FStar_Parser_AST.ReifiableLift (t0,t1);_}
                   -> (collect_term t0; collect_term t1)
               | FStar_Parser_AST.Tycon (uu____717,ts) ->
                   let ts1 =
                     FStar_List.map
                       (fun uu____732  ->
                          match uu____732 with | (x,doc1) -> x) ts
                      in
                   FStar_List.iter collect_tycon ts1
               | FStar_Parser_AST.Exception (uu____740,t) ->
                   FStar_Util.iter_opt t collect_term
               | FStar_Parser_AST.NewEffect ed -> collect_effect_decl ed
               | FStar_Parser_AST.Fsdoc uu____745 -> ()
               | FStar_Parser_AST.Pragma uu____746 -> ()
               | FStar_Parser_AST.TopLevelModule lid ->
                   (FStar_Util.incr num_of_toplevelmods;
                    (let uu____752 =
                       let uu____753 = FStar_ST.read num_of_toplevelmods  in
                       uu____753 > (Prims.parse_int "1")  in
                     if uu____752
                     then
                       let uu____756 =
                         let uu____757 =
                           let uu____758 = string_of_lid lid true  in
                           FStar_Util.format1
                             "Automatic dependency analysis demands one module per file (module %s not supported)"
                             uu____758
                            in
                         FStar_Errors.Err uu____757  in
                       raise uu____756
                     else ()))
             
             and collect_tycon uu___89_760 =
               match uu___89_760 with
               | FStar_Parser_AST.TyconAbstract (uu____761,binders,k) ->
                   (collect_binders binders;
                    FStar_Util.iter_opt k collect_term)
               | FStar_Parser_AST.TyconAbbrev (uu____769,binders,k,t) ->
                   (collect_binders binders;
                    FStar_Util.iter_opt k collect_term;
                    collect_term t)
               | FStar_Parser_AST.TyconRecord
                   (uu____779,binders,k,identterms) ->
                   (collect_binders binders;
                    FStar_Util.iter_opt k collect_term;
                    FStar_List.iter
                      (fun uu____803  ->
                         match uu____803 with
                         | (uu____808,t,uu____810) -> collect_term t)
                      identterms)
               | FStar_Parser_AST.TyconVariant
                   (uu____813,binders,k,identterms) ->
                   (collect_binders binders;
                    FStar_Util.iter_opt k collect_term;
                    FStar_List.iter
                      (fun uu____843  ->
                         match uu____843 with
                         | (uu____850,t,uu____852,uu____853) ->
                             FStar_Util.iter_opt t collect_term) identterms)
             
             and collect_effect_decl uu___90_858 =
               match uu___90_858 with
               | FStar_Parser_AST.DefineEffect (uu____859,binders,t,decls) ->
                   (collect_binders binders;
                    collect_term t;
                    collect_decls decls)
               | FStar_Parser_AST.RedefineEffect (uu____869,binders,t) ->
                   (collect_binders binders; collect_term t)
             
             and collect_binders binders =
               FStar_List.iter collect_binder binders
             
             and collect_binder uu___91_877 =
               match uu___91_877 with
               | {
                   FStar_Parser_AST.b = FStar_Parser_AST.Annotated
                     (uu____878,t);
                   FStar_Parser_AST.brange = uu____880;
                   FStar_Parser_AST.blevel = uu____881;
                   FStar_Parser_AST.aqual = uu____882;_} -> collect_term t
               | {
                   FStar_Parser_AST.b = FStar_Parser_AST.TAnnotated
                     (uu____883,t);
                   FStar_Parser_AST.brange = uu____885;
                   FStar_Parser_AST.blevel = uu____886;
                   FStar_Parser_AST.aqual = uu____887;_} -> collect_term t
               | { FStar_Parser_AST.b = FStar_Parser_AST.NoName t;
                   FStar_Parser_AST.brange = uu____889;
                   FStar_Parser_AST.blevel = uu____890;
                   FStar_Parser_AST.aqual = uu____891;_} -> collect_term t
               | uu____892 -> ()
             
             and collect_term t = collect_term' t.FStar_Parser_AST.tm
             
             and collect_constant uu___92_894 =
               match uu___92_894 with
               | FStar_Const.Const_int (uu____895,Some (signedness,width)) ->
                   let u =
                     match signedness with
                     | FStar_Const.Unsigned  -> "u"
                     | FStar_Const.Signed  -> ""  in
                   let w =
                     match width with
                     | FStar_Const.Int8  -> "8"
                     | FStar_Const.Int16  -> "16"
                     | FStar_Const.Int32  -> "32"
                     | FStar_Const.Int64  -> "64"  in
                   let uu____905 = FStar_Util.format2 "fstar.%sint%s" u w  in
                   add_dep uu____905
               | uu____906 -> ()
             
             and collect_term' uu___93_907 =
               match uu___93_907 with
               | FStar_Parser_AST.Wild  -> ()
               | FStar_Parser_AST.Const c -> collect_constant c
               | FStar_Parser_AST.Op (s,ts) ->
                   (if (FStar_Ident.text_of_id s) = "@"
                    then
                      (let uu____914 =
                         let uu____915 =
                           FStar_Ident.lid_of_path
                             (FStar_Ident.path_of_text
                                "FStar.List.Tot.Base.append")
                             FStar_Range.dummyRange
                            in
                         FStar_Parser_AST.Name uu____915  in
                       collect_term' uu____914)
                    else ();
                    FStar_List.iter collect_term ts)
               | FStar_Parser_AST.Tvar uu____917 -> ()
               | FStar_Parser_AST.Uvar uu____918 -> ()
               | FStar_Parser_AST.Var lid -> record_lid lid
               | FStar_Parser_AST.Projector (lid,uu____921) -> record_lid lid
               | FStar_Parser_AST.Discrim lid -> record_lid lid
               | FStar_Parser_AST.Name lid -> record_lid lid
               | FStar_Parser_AST.Construct (lid,termimps) ->
                   (if (FStar_List.length termimps) = (Prims.parse_int "1")
                    then record_lid lid
                    else ();
                    FStar_List.iter
                      (fun uu____940  ->
                         match uu____940 with
                         | (t,uu____944) -> collect_term t) termimps)
               | FStar_Parser_AST.Abs (pats,t) ->
                   (collect_patterns pats; collect_term t)
               | FStar_Parser_AST.App (t1,t2,uu____952) ->
                   (collect_term t1; collect_term t2)
               | FStar_Parser_AST.Let (uu____954,patterms,t) ->
                   (FStar_List.iter
                      (fun uu____966  ->
                         match uu____966 with
                         | (pat,t1) -> (collect_pattern pat; collect_term t1))
                      patterms;
                    collect_term t)
               | FStar_Parser_AST.LetOpen (lid,t) ->
                   (record_open true lid; collect_term t)
               | FStar_Parser_AST.Bind (uu____975,t1,t2) ->
                   (collect_term t1; collect_term t2)
               | FStar_Parser_AST.Seq (t1,t2) ->
                   (collect_term t1; collect_term t2)
               | FStar_Parser_AST.If (t1,t2,t3) ->
                   (collect_term t1; collect_term t2; collect_term t3)
               | FStar_Parser_AST.Match (t,bs) ->
                   (collect_term t; collect_branches bs)
               | FStar_Parser_AST.TryWith (t,bs) ->
                   (collect_term t; collect_branches bs)
               | FStar_Parser_AST.Ascribed (t1,t2,None ) ->
                   (collect_term t1; collect_term t2)
               | FStar_Parser_AST.Ascribed (t1,t2,Some tac) ->
                   (collect_term t1; collect_term t2; collect_term tac)
               | FStar_Parser_AST.Record (t,idterms) ->
                   (FStar_Util.iter_opt t collect_term;
                    FStar_List.iter
                      (fun uu____1036  ->
                         match uu____1036 with
                         | (uu____1039,t1) -> collect_term t1) idterms)
               | FStar_Parser_AST.Project (t,uu____1042) -> collect_term t
               | FStar_Parser_AST.Product (binders,t) ->
                   (collect_binders binders; collect_term t)
               | FStar_Parser_AST.Sum (binders,t) ->
                   (collect_binders binders; collect_term t)
               | FStar_Parser_AST.QForall (binders,ts,t) ->
                   (collect_binders binders;
                    FStar_List.iter (FStar_List.iter collect_term) ts;
                    collect_term t)
               | FStar_Parser_AST.QExists (binders,ts,t) ->
                   (collect_binders binders;
                    FStar_List.iter (FStar_List.iter collect_term) ts;
                    collect_term t)
               | FStar_Parser_AST.Refine (binder,t) ->
                   (collect_binder binder; collect_term t)
               | FStar_Parser_AST.NamedTyp (uu____1080,t) -> collect_term t
               | FStar_Parser_AST.Paren t -> collect_term t
               | FStar_Parser_AST.Assign (uu____1083,t) -> collect_term t
               | FStar_Parser_AST.Requires (t,uu____1086) -> collect_term t
               | FStar_Parser_AST.Ensures (t,uu____1090) -> collect_term t
               | FStar_Parser_AST.Labeled (t,uu____1094,uu____1095) ->
                   collect_term t
               | FStar_Parser_AST.Attributes cattributes ->
                   FStar_List.iter collect_term cattributes
             
             and collect_patterns ps = FStar_List.iter collect_pattern ps
             
             and collect_pattern p = collect_pattern' p.FStar_Parser_AST.pat
             
             and collect_pattern' uu___94_1101 =
               match uu___94_1101 with
               | FStar_Parser_AST.PatWild  -> ()
               | FStar_Parser_AST.PatOp uu____1102 -> ()
               | FStar_Parser_AST.PatConst uu____1103 -> ()
               | FStar_Parser_AST.PatApp (p,ps) ->
                   (collect_pattern p; collect_patterns ps)
               | FStar_Parser_AST.PatVar uu____1109 -> ()
               | FStar_Parser_AST.PatName uu____1113 -> ()
               | FStar_Parser_AST.PatTvar uu____1114 -> ()
               | FStar_Parser_AST.PatList ps -> collect_patterns ps
               | FStar_Parser_AST.PatOr ps -> collect_patterns ps
               | FStar_Parser_AST.PatTuple (ps,uu____1123) ->
                   collect_patterns ps
               | FStar_Parser_AST.PatRecord lidpats ->
                   FStar_List.iter
                     (fun uu____1132  ->
                        match uu____1132 with
                        | (uu____1135,p) -> collect_pattern p) lidpats
               | FStar_Parser_AST.PatAscribed (p,t) ->
                   (collect_pattern p; collect_term t)
             
             and collect_branches bs = FStar_List.iter collect_branch bs
             
             and collect_branch uu____1150 =
               match uu____1150 with
               | (pat,t1,t2) ->
                   (collect_pattern pat;
                    FStar_Util.iter_opt t1 collect_term;
                    collect_term t2)
              in
             let uu____1162 = FStar_Parser_Driver.parse_file filename  in
             match uu____1162 with
             | (ast,uu____1170) -> (collect_file ast; FStar_ST.read deps))
  
let print_graph graph =
  FStar_Util.print_endline
    "A DOT-format graph has been dumped in the current directory as dep.graph";
  FStar_Util.print_endline
    "With GraphViz installed, try: fdp -Tpng -odep.png dep.graph";
  FStar_Util.print_endline "Hint: cat dep.graph | grep -v _ | grep -v prims";
  (let uu____1199 =
     let uu____1200 =
       let uu____1201 =
         let uu____1202 =
           let uu____1204 =
             let uu____1206 = FStar_Util.smap_keys graph  in
             FStar_List.unique uu____1206  in
           FStar_List.collect
             (fun k  ->
                let deps =
                  let uu____1214 =
                    let uu____1218 = FStar_Util.smap_try_find graph k  in
                    FStar_Util.must uu____1218  in
                  fst uu____1214  in
                let r s = FStar_Util.replace_char s '.' '_'  in
                FStar_List.map
                  (fun dep1  ->
                     FStar_Util.format2 "  %s -> %s" (r k) (r dep1)) deps)
             uu____1204
            in
         FStar_String.concat "\n" uu____1202  in
       Prims.strcat uu____1201 "\n}\n"  in
     Prims.strcat "digraph {\n" uu____1200  in
   FStar_Util.write_file "dep.graph" uu____1199)
  
let collect :
  verify_mode ->
    Prims.string Prims.list ->
      ((Prims.string * Prims.string Prims.list) Prims.list * Prims.string
        Prims.list * (Prims.string Prims.list * color) FStar_Util.smap)
  =
  fun verify_mode  ->
    fun filenames  ->
      let graph = FStar_Util.smap_create (Prims.parse_int "41")  in
      let verify_flags =
        let uu____1280 = FStar_Options.verify_module ()  in
        FStar_List.map
          (fun f  ->
             let uu____1286 = FStar_Util.mk_ref false  in (f, uu____1286))
          uu____1280
         in
      let partial_discovery =
        let uu____1293 =
          (FStar_Options.verify_all ()) || (FStar_Options.extract_all ())  in
        Prims.op_Negation uu____1293  in
      let m = build_map filenames  in
      let file_names_of_key k =
        let uu____1299 =
          let uu____1304 = FStar_Util.smap_try_find m k  in
          FStar_Util.must uu____1304  in
        match uu____1299 with
        | (intf,impl) ->
            (match (intf, impl) with
             | (None ,None ) -> failwith "Impossible"
             | (None ,Some i) -> i
             | (Some i,None ) -> i
             | (Some i,uu____1335) when partial_discovery -> i
             | (Some i,Some j) -> Prims.strcat i (Prims.strcat " && " j))
         in
      let collect_one1 = collect_one verify_flags verify_mode  in
      let rec discover_one is_user_provided_filename interface_only key =
        let uu____1361 =
          let uu____1362 = FStar_Util.smap_try_find graph key  in
          uu____1362 = None  in
        if uu____1361
        then
          let uu____1377 =
            let uu____1382 = FStar_Util.smap_try_find m key  in
            FStar_Util.must uu____1382  in
          match uu____1377 with
          | (intf,impl) ->
              let intf_deps =
                match intf with
                | Some intf1 ->
                    collect_one1 is_user_provided_filename m intf1
                | None  -> []  in
              let impl_deps =
                match (impl, intf) with
                | (Some impl1,Some uu____1412) when interface_only -> []
                | (Some impl1,uu____1416) ->
                    collect_one1 is_user_provided_filename m impl1
                | (None ,uu____1420) -> []  in
              let deps =
                FStar_List.unique (FStar_List.append impl_deps intf_deps)  in
              (FStar_Util.smap_add graph key (deps, White);
               FStar_List.iter (discover_one false partial_discovery) deps)
        else ()  in
      let discover_command_line_argument f =
        let m1 = lowercase_module_name f  in
        let interface_only =
          (is_interface f) &&
            (let uu____1438 =
               FStar_List.existsML
                 (fun f1  ->
                    (let uu____1440 = lowercase_module_name f1  in
                     uu____1440 = m1) && (is_implementation f1)) filenames
                in
             Prims.op_Negation uu____1438)
           in
        discover_one true interface_only m1  in
      FStar_List.iter discover_command_line_argument filenames;
      (let immediate_graph = FStar_Util.smap_copy graph  in
       let topologically_sorted = FStar_Util.mk_ref []  in
       let rec discover cycle key =
         let uu____1465 =
           let uu____1469 = FStar_Util.smap_try_find graph key  in
           FStar_Util.must uu____1469  in
         match uu____1465 with
         | (direct_deps,color) ->
             (match color with
              | Gray  ->
                  (FStar_Util.print1
                     "Warning: recursive dependency on module %s\n" key;
                   (let cycle1 =
                      FStar_All.pipe_right cycle
                        (FStar_List.map file_names_of_key)
                       in
                    FStar_Util.print1
                      "The cycle contains a subset of the modules in:\n%s \n"
                      (FStar_String.concat "\n`used by` " cycle1);
                    print_graph immediate_graph;
                    FStar_Util.print_string "\n";
                    FStar_All.exit (Prims.parse_int "1")))
              | Black  -> direct_deps
              | White  ->
                  (FStar_Util.smap_add graph key (direct_deps, Gray);
                   (let all_deps =
                      let uu____1502 =
                        let uu____1504 =
                          FStar_List.map
                            (fun dep1  ->
                               let uu____1509 = discover (key :: cycle) dep1
                                  in
                               dep1 :: uu____1509) direct_deps
                           in
                        FStar_List.flatten uu____1504  in
                      FStar_List.unique uu____1502  in
                    FStar_Util.smap_add graph key (all_deps, Black);
                    (let uu____1517 =
                       let uu____1519 = FStar_ST.read topologically_sorted
                          in
                       key :: uu____1519  in
                     FStar_ST.write topologically_sorted uu____1517);
                    all_deps)))
          in
       let discover1 = discover []  in
       let must_find k =
         let uu____1536 =
           let uu____1541 = FStar_Util.smap_try_find m k  in
           FStar_Util.must uu____1541  in
         match uu____1536 with
         | (Some intf,Some impl) when
             (Prims.op_Negation partial_discovery) &&
               (let uu____1560 =
                  FStar_List.existsML
                    (fun f  ->
                       let uu____1562 = lowercase_module_name f  in
                       uu____1562 = k) filenames
                   in
                Prims.op_Negation uu____1560)
             -> [intf; impl]
         | (Some intf,Some impl) when
             FStar_List.existsML
               (fun f  ->
                  (is_implementation f) &&
                    (let uu____1568 = lowercase_module_name f  in
                     uu____1568 = k)) filenames
             -> [intf; impl]
         | (Some intf,uu____1570) -> [intf]
         | (None ,Some impl) -> [impl]
         | (None ,None ) -> []  in
       let must_find_r f =
         let uu____1584 = must_find f  in FStar_List.rev uu____1584  in
       let by_target =
         let uu____1591 =
           let uu____1593 = FStar_Util.smap_keys graph  in
           FStar_List.sortWith (fun x  -> fun y  -> FStar_String.compare x y)
             uu____1593
            in
         FStar_List.collect
           (fun k  ->
              let as_list = must_find k  in
              let is_interleaved =
                (FStar_List.length as_list) = (Prims.parse_int "2")  in
              FStar_List.map
                (fun f  ->
                   let should_append_fsti =
                     (is_implementation f) && is_interleaved  in
                   let k1 = lowercase_module_name f  in
                   let suffix =
                     let uu____1617 =
                       let uu____1622 = FStar_Util.smap_try_find m k1  in
                       FStar_Util.must uu____1622  in
                     match uu____1617 with
                     | (Some intf,uu____1638) when should_append_fsti ->
                         [intf]
                     | uu____1642 -> []  in
                   let deps =
                     let uu____1649 = discover1 k1  in
                     FStar_List.rev uu____1649  in
                   let deps_as_filenames =
                     let uu____1653 = FStar_List.collect must_find deps  in
                     FStar_List.append uu____1653 suffix  in
                   (f, deps_as_filenames)) as_list) uu____1591
          in
       let topologically_sorted1 =
         let uu____1658 = FStar_ST.read topologically_sorted  in
         FStar_List.collect must_find_r uu____1658  in
       FStar_List.iter
         (fun uu____1667  ->
            match uu____1667 with
            | (m1,r) ->
                let uu____1675 =
                  (let uu____1676 = FStar_ST.read r  in
                   Prims.op_Negation uu____1676) &&
                    (let uu____1679 = FStar_Options.interactive ()  in
                     Prims.op_Negation uu____1679)
                   in
                if uu____1675
                then
                  let maybe_fst =
                    let k = FStar_String.length m1  in
                    let uu____1683 =
                      (k > (Prims.parse_int "4")) &&
                        (let uu____1687 =
                           FStar_String.substring m1
                             (k - (Prims.parse_int "4"))
                             (Prims.parse_int "4")
                            in
                         uu____1687 = ".fst")
                       in
                    if uu____1683
                    then
                      let uu____1691 =
                        FStar_String.substring m1 (Prims.parse_int "0")
                          (k - (Prims.parse_int "4"))
                         in
                      FStar_Util.format1 " Did you mean %s ?" uu____1691
                    else ""  in
                  let uu____1696 =
                    let uu____1697 =
                      FStar_Util.format3
                        "You passed --verify_module %s but I found no file that contains [module %s] in the dependency graph.%s\n"
                        m1 m1 maybe_fst
                       in
                    FStar_Errors.Err uu____1697  in
                  raise uu____1696
                else ()) verify_flags;
       (by_target, topologically_sorted1, immediate_graph))
  
let print_make :
  (Prims.string * Prims.string Prims.list) Prims.list -> Prims.unit =
  fun deps  ->
    FStar_List.iter
      (fun uu____1722  ->
         match uu____1722 with
         | (f,deps1) ->
             let deps2 =
               FStar_List.map
                 (fun s  -> FStar_Util.replace_chars s ' ' "\\ ") deps1
                in
             FStar_Util.print2 "%s: %s\n" f (FStar_String.concat " " deps2))
      deps
  
let print uu____1752 =
  match uu____1752 with
  | (make_deps,uu____1765,graph) ->
      let uu____1783 = FStar_Options.dep ()  in
      (match uu____1783 with
       | Some "make" -> print_make make_deps
       | Some "graph" -> print_graph graph
       | Some uu____1785 ->
           raise (FStar_Errors.Err "unknown tool for --dep\n")
       | None  -> ())
  