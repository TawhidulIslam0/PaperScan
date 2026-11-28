import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_item.dart';
class DocumentStore {
 DocumentStore._(); static final instance=DocumentStore._();
 late SharedPreferences prefs; late Directory docsDir;
 static const _key='paperscan_docs_v1';
 Future<void> init() async {prefs=await SharedPreferences.getInstance(); final base=await getApplicationDocumentsDirectory(); docsDir=Directory('${base.path}/PaperScan'); if(!await docsDir.exists()) await docsDir.create(recursive:true);}
 List<DocumentItem> get all { final raw=prefs.getString(_key); if(raw==null)return []; try{return (jsonDecode(raw) as List).map((e)=>DocumentItem.fromJson(e)).where((d)=>File(d.pdfPath).existsSync()).toList();}catch(_){return [];} }
 Future<void> save(DocumentItem doc) async {final list=all.where((d)=>d.id!=doc.id).toList()..insert(0,doc); await prefs.setString(_key,jsonEncode(list.map((e)=>e.toJson()).toList()));}
 Future<void> delete(DocumentItem doc) async {try{await File(doc.pdfPath).delete();}catch(_){} await prefs.setString(_key,jsonEncode(all.where((d)=>d.id!=doc.id).map((e)=>e.toJson()).toList()));}
 Future<void> rename(DocumentItem doc,String title) async {await save(DocumentItem(id:doc.id,title:title,pdfPath:doc.pdfPath,createdAt:doc.createdAt,pageCount:doc.pageCount,folder:doc.folder));}
}
