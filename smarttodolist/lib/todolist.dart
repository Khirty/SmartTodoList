// todolist.dart - Ultra Modern Design with Logout, AI Chat & Firebase
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'chat_screen.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final TextEditingController searchController = TextEditingController();
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> tasks = [];
  String selectedCategory = "General";
  String selectedPriority = "Medium";
  String? filterCategory;
  String? filterPriority;

  final categoryColors = {
    "General": Color(0xFF667eea),
    "Work": Color(0xFF06d6a0),
    "School": Color(0xFFffd166),
    "Personal": Color(0xFFef476f),
  };

  final priorities = ["High", "Medium", "Low"];

  @override
  void initState() {
    super.initState();
    loadTasksFromDB();
  }

  Future<void> loadTasksFromDB() async {
    final snapshot = await _firestore.collection('tasks').get();
    setState(() {
      tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addTaskToDB(Map<String, dynamic> task) async {
    final docRef = await _firestore.collection('tasks').add(task);
    task['id'] = docRef.id;
  }

  Future<void> updateTaskInDB(String id, Map<String, dynamic> task) async {
    await _firestore.collection('tasks').doc(id).update(task);
  }

  Future<void> deleteTaskFromDB(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  void addTaskModal() {
    final nameCtrl = TextEditingController();
    String modalCat = selectedCategory;
    String modalPrio = selectedPriority;
    Uint8List? modalImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_task, color: Color(0xFF667eea)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Create New Task",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Task Name",
                      prefixIcon: const Icon(Icons.edit_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: modalCat,
                    items: categoryColors.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => modalCat = v);
                    },
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: modalPrio,
                    items: priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => modalPrio = v);
                    },
                    decoration: InputDecoration(
                      labelText: "Priority",
                      prefixIcon: const Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setModalState(() => modalImage = bytes);
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(modalImage != null ? "Image Added ✓" : "Add Image"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            final isoDate = DateTime.now().toIso8601String().substring(0, 10);
                            final newTask = {
                              "name": nameCtrl.text.trim(),
                              "done": false,
                              "imageBytes": modalImage,
                              "category": modalCat,
                              "priority": modalPrio,
                              "date": isoDate,
                            };
                            setState(() => tasks.add(newTask));
                            await addTaskToDB(newTask);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF667eea),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Create", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void toggleTask(int index) async {
    setState(() => tasks[index]["done"] = !tasks[index]["done"]);
    if (tasks[index].containsKey('id')) {
      await updateTaskInDB(tasks[index]['id'], {"done": tasks[index]["done"]});
    }
  }

  void confirmDelete(int index) async {
    final id = tasks[index]['id'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              setState(() => tasks.removeAt(index));
              if (id != null) await deleteTaskFromDB(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void editTask(int index) {
    final editController = TextEditingController(text: tasks[index]["name"]);
    String newCategory = tasks[index]["category"];
    String newPriority = tasks[index]["priority"];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit, color: Color(0xFF667eea)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Edit Task",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    labelText: "Task Name",
                    prefixIcon: const Icon(Icons.edit_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: newCategory,
                  items: categoryColors.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => newCategory = v);
                  },
                  decoration: InputDecoration(
                    labelText: "Category",
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: newPriority,
                  items: priorities
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => newPriority = v);
                  },
                  decoration: InputDecoration(
                    labelText: "Priority",
                    prefixIcon: const Icon(Icons.flag_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          tasks[index]["name"] = editController.text.trim();
                          tasks[index]["category"] = newCategory;
                          tasks[index]["priority"] = newPriority;
                          setState(() {});

                          if (tasks[index].containsKey('id')) {
                            await updateTaskInDB(tasks[index]['id'], {
                              "name": tasks[index]["name"],
                              "category": newCategory,
                              "priority": newPriority
                            });
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getAiSuggestion() {
    final total = tasks.length;
    final completed = tasks.where((t) => t["done"]).length;
    final incomplete = total - completed;

    if (total == 0) return "Start by adding your first task! 🚀";
    if (incomplete >= 5) return "You have many pending tasks. Try finishing the easiest one! 💪";
    if (completed > incomplete) return "Great job! You're completing tasks quickly! 🎉";
    if (incomplete == 1) return "Only one task left! You can do it! 🔥";
    return "Keep going — you're doing great! ✨";
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
            onPressed: () {
              _authService.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTasks = tasks
        .where((t) => t["name"].toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();

    if (filterCategory != null) {
      filteredTasks = filteredTasks.where((t) => t["category"] == filterCategory).toList();
    }
    if (filterPriority != null) {
      filteredTasks = filteredTasks.where((t) => t["priority"] == filterPriority).toList();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf5f7fa), Color(0xFFc3cfe2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Smart To-Do",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFef476f)),
                      tooltip: 'Logout',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        setState(() {
                          if (value.startsWith("cat_")) {
                            filterCategory = value.replaceFirst("cat_", "");
                          } else if (value.startsWith("prio_")) {
                            filterPriority = value.replaceFirst("prio_", "");
                          } else if (value == "clear_all") {
                            filterCategory = null;
                            filterPriority = null;
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: "clear_all",
                          child: Row(
                            children: const [
                              Icon(Icons.clear_all, size: 20),
                              SizedBox(width: 12),
                              Text("Clear Filters"),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        ...categoryColors.keys.map((c) =>
                            PopupMenuItem<String>(value: "cat_$c", child: Text(c))),
                        const PopupMenuDivider(),
                        ...priorities.map((p) =>
                            PopupMenuItem<String>(value: "prio_$p", child: Text(p))),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFffd166), Color(0xFFef476f)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFef476f).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                getAiSuggestion(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Color(0xFF667eea)),
                            hintText: "Search tasks...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: filteredTasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No tasks found 📝",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final t = filteredTasks[index];
                                  final realIndex = tasks.indexOf(t);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: t["imageBytes"] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.memory(
                                                t["imageBytes"],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: categoryColors[t["category"]]!.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.task_alt,
                                                color: categoryColors[t["category"]],
                                              ),
                                            ),
                                      title: Text(
                                        t["name"],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2d3748),
                                          decoration: t["done"] ? TextDecoration.lineThrough : TextDecoration.none,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: categoryColors[t["category"]]!.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  t["category"],
                                                  style: TextStyle(
                                                    color: categoryColors[t["category"]],
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "• ${t["priority"]}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              t["done"] ? Icons.check_circle : Icons.circle_outlined,
                                              color: t["done"] ? Color(0xFF06d6a0) : Colors.grey,
                                            ),
                                            onPressed: () => toggleTask(realIndex),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF667eea)),
                                            onPressed: () => editTask(realIndex),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFef476f)),
                                            onPressed: () => confirmDelete(realIndex),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Chat',
                  pageBuilder: (context, anim1, anim2) => Align(
                    alignment: Alignment.centerRight,
                    child: ChatScreen(tasks: tasks),
                  ),
                );
              },
              heroTag: 'chat',
              backgroundColor: Color(0xFF764ba2),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: addTaskModal,
              heroTag: 'add',
              backgroundColor: Color(0xFF667eea),
              elevation: 8,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
