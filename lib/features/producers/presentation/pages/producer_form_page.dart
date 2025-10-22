import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';

class ProducerFormPage extends ConsumerStatefulWidget {
  final ProducerEntity? producer;

  const ProducerFormPage({
    super.key,
    this.producer,
  });

  @override
  ConsumerState<ProducerFormPage> createState() => _ProducerFormPageState();
}

class _ProducerFormPageState extends ConsumerState<ProducerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.producer != null) {
      _nameController.text = widget.producer!.name;
      _regionController.text = widget.producer!.region ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать производителя' : 'Добавить производителя'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _isLoading ? null : _deleteProducer,
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildRegionField(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producer != null ? 'Редактирование' : 'Новый производитель',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.producer != null
                      ? 'Измените информацию о производителе'
                      : 'Заполните информацию о новом производителе',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Название производителя *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Введите название производителя',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Название производителя обязательно';
            }
            if (value.trim().length < 2) {
              return 'Название должно содержать минимум 2 символа';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildRegionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Регион',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _regionController,
          decoration: InputDecoration(
            hintText: 'Введите регион (необязательно)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _cancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProducer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.producer != null ? 'Сохранить' : 'Добавить'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProducer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final producer = ProducerEntity(
        id: widget.producer?.id ?? 0,
        name: _nameController.text.trim(),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        productsCount: widget.producer?.productsCount ?? 0,
        createdAt: widget.producer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.producer != null) {
        await ref.read(producersProvider.notifier).updateProducer(
              widget.producer!.id,
              producer,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Производитель успешно обновлен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ref.read(producersProvider.notifier).createProducer(producer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Производитель успешно добавлен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProducer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить производителя'),
        content: Text(
          'Вы уверены, что хотите удалить производителя "${widget.producer!.name}"?\n\n'
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(producersProvider.notifier).deleteProducer(widget.producer!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Производитель успешно удален'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }
}
