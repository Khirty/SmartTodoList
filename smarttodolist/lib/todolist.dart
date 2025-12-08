import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final TextEditingController taskController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];
  Uint8List? selectedImage;

  String selectedCategory = "General";
  String selectedPriority = "Medium";

  // Combined filters (both may be active)
  String? filterCategory;
  String? filterPriority;

  final categoryColors = {
    "General": Colors.blue,
    "Work": Colors.green,
    "School": Colors.orange,
    "Personal": Colors.purple,
  };

  final priorities = ["High", "Medium", "Low"];

  Future<void> pickTaskImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => selectedImage = bytes);
    }
  }

  void addTaskModal() {
    final nameCtrl = TextEditingController();
    String modalCat = selectedCategory;
    String modalPrio = selectedPriority;
    // local image preview for modal (so we don't override global unless created)
    Uint8List? modalImage = selectedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Create Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Task Name"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: modalCat,
                  items: categoryColors.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => modalCat = v);
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: modalPrio,
                  items: priorities
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => modalPrio = v);
                  },
                  decoration: const InputDecoration(labelText: "Priority"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setModalState(() => modalImage = bytes);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Add Image"),
                    ),
                    const SizedBox(width: 12),
                    if (modalImage != null)
                      const Text(
                        "Image will be attached",
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                // generate ISO date YYYY-MM-DD
                final isoDate = DateTime.now().toIso8601String().substring(
                  0,
                  10,
                );
                setState(() {
                  tasks.add({
                    "name": nameCtrl.text.trim(),
                    "done": false,
                    "imageBytes": modalImage,
                    "category": modalCat,
                    "priority": modalPrio,
                    "date": isoDate, // ISO format stored here
                  });
                  // reset selections after adding
                  selectedImage = null;
                  selectedCategory = "General";
                  selectedPriority = "Medium";
                });
                Navigator.pop(ctx);
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void toggleTask(int index) {
    setState(() => tasks[index]["done"] = !tasks[index]["done"]);
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () {
              setState(() => tasks.removeAt(index));
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
      builder: (_) => AlertDialog(
        title: const Text("Edit Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: newCategory,
              items: categoryColors.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) newCategory = v;
              },
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: newPriority,
              items: priorities
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) newPriority = v;
              },
              decoration: const InputDecoration(labelText: "Priority"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () {
              setState(() {
                tasks[index]["name"] = editController.text;
                tasks[index]["category"] = newCategory;
                tasks[index]["priority"] = newPriority;
                // keep original date untouched
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String getAiSuggestion() {
    final total = tasks.length;
    final completed = tasks.where((t) => t["done"]).length;
    final incomplete = total - completed;
    final withImages = tasks.where((t) => t["imageBytes"] != null).length;

    if (total == 0) return "Start by adding your first task!";
    if (incomplete >= 5) {
      return "You have many pending tasks. Try finishing the easiest one!";
    }
    if (completed > incomplete) {
      return "Great job! You're completing tasks quickly!";
    }
    if (withImages >= 3) return "Nice! You added many image-based tasks.";
    if (incomplete == 1) return "Only one task left! You can do it!";
    return "Keep going — you're doing great!";
  }

  void clearAllFilters() {
    setState(() {
      filterCategory = null;
      filterPriority = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTasks = tasks
        .where(
          (t) => t["name"].toLowerCase().contains(
            searchController.text.toLowerCase(),
          ),
        )
        .toList();

    // Apply combined filters (both may be active)
    if (filterCategory != null) {
      filteredTasks = filteredTasks
          .where((t) => t["category"] == filterCategory)
          .toList();
    }

    if (filterPriority != null) {
      filteredTasks = filteredTasks
          .where((t) => t["priority"] == filterPriority)
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6E9C8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Smart To-Do",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
            fontSize: 26,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.brown),
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
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: "clear_all",
                child: const Text("Clear Filters"),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  "Categories",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...categoryColors.keys
                  .map(
                    (c) =>
                        PopupMenuItem<String>(value: "cat_$c", child: Text(c)),
                  )
                  .toList(),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  "Priorities",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...priorities
                  .map(
                    (p) =>
                        PopupMenuItem<String>(value: "prio_$p", child: Text(p)),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: addTaskModal,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AI suggestion box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6C6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      getAiSuggestion(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar & active filter chips
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search tasks...",
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),

            // Active filters row (shows chips if filters applied)
            if (filterCategory != null || filterPriority != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    if (filterCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text("Category: $filterCategory"),
                          selected: true,
                          onSelected: (_) {
                            setState(() {
                              filterCategory = null;
                            });
                          },
                          avatar: Icon(
                            Icons.label,
                            color: categoryColors[filterCategory],
                          ),
                        ),
                      ),
                    if (filterPriority != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text("Priority: $filterPriority"),
                          selected: true,
                          onSelected: (_) {
                            setState(() {
                              filterPriority = null;
                            });
                          },
                          avatar: const Icon(Icons.priority_high),
                        ),
                      ),
                    TextButton(
                      onPressed: clearAllFilters,
                      child: const Text("Clear Filters"),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(
                      child: Text(
                        "No tasks found 📝",
                        style: TextStyle(color: Colors.brown, fontSize: 18),
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
                          ),
                          child: ListTile(
                            leading: t["imageBytes"] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      t["imageBytes"],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.task_alt,
                                    color: Colors.orange,
                                  ),
                            title: Text(
                              t["name"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.brown,
                                decoration: t["done"]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: categoryColors[t["category"]]!
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        t["category"],
                                        style: TextStyle(
                                          color: categoryColors[t["category"]],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Priority: ${t["priority"]}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Show ISO date (YYYY-MM-DD)
                                Text(
                                  "${t["date"] ?? ''}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    t["done"]
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => toggleTask(realIndex),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () => editTask(realIndex),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
    );
  }
}
