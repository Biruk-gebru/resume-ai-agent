import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:docx_template/docx_template.dart';
import 'dart:io' show File;


void main() {
  runApp(ResumeAiApp());
}

class ResumeAiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume AI Agent',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _uploadResult = "";
  String _bestResume = "";
  String _optimizedResume = "";
  String _statusMessage = "";

  // Controllers for job description and resume content in the find/optimize flow.
  TextEditingController jobDescController = TextEditingController();

  // URLs for our endpoints
  final String uploadUrl = "http://localhost:8000/api/upload-resume";
  final String bestResumeUrl = "http://localhost:8000/api/best-resume";
  final String optimizeUrl = "http://localhost:8000/api/optimize-resume";

  @override
  void initState() {
    super.initState();
    // Three tabs: Upload, Find Best & Optimize, and (optional) History if needed.
    _tabController = TabController(length: 2, vsync: this);
  }

  // Upload Tab: Select and upload a resume file.
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      try {
        var request = http.MultipartRequest("POST", Uri.parse(uploadUrl));
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          setState(() {
            _uploadResult = "Upload successful. Resume stored in database.";
            _statusMessage = "You can now use the Find Best & Optimize tab.";
          });
        } else {
          setState(() {
            _uploadResult = "Upload failed: ${response.statusCode}\n${response.body}";
          });
        }
      } catch (e) {
        setState(() {
          _uploadResult = "Error during upload: $e";
        });
      }
    } else {
      setState(() {
        _uploadResult = "No file selected.";
      });
    }
  }

  // Find Best & Optimize Tab: Find the best matching resume and then optimize it.
  Future<void> _findBestResume() async {
    String jobDescription = jobDescController.text.trim();
    if (jobDescription.isEmpty) {
      setState(() => _statusMessage = "Please enter a job description.");
      return;
    }
    setState(() {
      _statusMessage = "Finding best matching resume...";
      _bestResume = "";
      _optimizedResume = "";
    });
    try {
      var response = await http.post(
        Uri.parse(bestResumeUrl),
        body: {'job_description': jobDescription},
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _bestResume = data['best_resume'] ?? "";
          _statusMessage = "Best resume found. Tap 'Optimize Resume' to improve it.";
        });
      } else {
        setState(() {
          _statusMessage = "Error finding best resume: ${response.statusCode} ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _optimizeResume() async {
    String jobDescription = jobDescController.text.trim();
    if (_bestResume.isEmpty) {
      setState(() {
        _statusMessage = "No best resume available to optimize.";
      });
      return;
    }
    setState(() {
      _statusMessage = "Optimizing resume...";
      _optimizedResume = "";
    });
    try {
      var response = await http.post(
        Uri.parse(optimizeUrl),
        body: {
          'job_description': jobDescription,
          'resume_content': _bestResume,
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _optimizedResume = data['optimized_resume'] ?? "";
          _statusMessage = "Optimization complete.";
        });
      } else {
        setState(() {
          _statusMessage = "Error optimizing resume: ${response.statusCode} ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    }
  }


  Future<void> _downloadOptimizedResume(BuildContext context, String optimizedResume) async {
    if (optimizedResume.isEmpty) return;
    try {
      // Replace any escaped newline characters with actual newlines.
      String formattedText = optimizedResume.replaceAll("\\n", "\n");

      if (kIsWeb) {
        // On web, create a Blob and trigger a download.
        final bytes = utf8.encode(formattedText);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = "optimized_resume.txt";
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Optimized resume downloaded as a txt file.")),
        );
      } else {
        // On mobile/desktop, save the text file to the device.
        final directory = await getApplicationDocumentsDirectory();
        final filePath = "${directory.path}/optimized_resume.txt";
        final file = File(filePath);
        await file.writeAsString(formattedText);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Optimized resume saved to $filePath")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving file: $e")),
      );
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    jobDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resume AI Agent'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Upload Resume"),
            Tab(text: "Find & Optimize"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Upload Resume
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _pickAndUploadFile,
                  child: Text("Select and Upload Resume (.docx)"),
                ),
                SizedBox(height: 16),
                Text(_uploadResult),
              ],
            ),
          ),
          // Tab 2: Find Best & Optimize
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: jobDescController,
                    decoration: InputDecoration(
                      labelText: "Job Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _findBestResume,
                    child: Text("Find Best Resume"),
                  ),
                  SizedBox(height: 16),
                  if (_bestResume.isNotEmpty) ...[
                    Text(
                      "Best Matching Resume:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(_bestResume),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _optimizeResume,
                      child: Text("Optimize This Resume"),
                    ),
                  ],
                  SizedBox(height: 16),
                  if (_optimizedResume.isNotEmpty) ...[
                    Text(
                      "Optimized Resume:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(_optimizedResume),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _optimizedResume.isNotEmpty
                          ? () => _downloadOptimizedResume(context, _optimizedResume)
                          : null,
                      child: Text("Download Optimized Resume"),
                    ),

                  ],
                  SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
