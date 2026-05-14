import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../providers/finance_provider.dart';

class RegisterCinemaVisitDialog extends ConsumerStatefulWidget {
  final Movie movie;
  final VoidCallback? onSuccess;

  const RegisterCinemaVisitDialog({
    super.key,
    required this.movie,
    this.onSuccess,
  });

  @override
  ConsumerState<RegisterCinemaVisitDialog> createState() =>
      _RegisterCinemaVisitDialogState();
}

class _RegisterCinemaVisitDialogState
    extends ConsumerState<RegisterCinemaVisitDialog> {
  late TextEditingController _cinemaController;
  late TextEditingController _priceController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cinemaController = TextEditingController();
    _priceController = TextEditingController(text: '8.50');
  }

  @override
  void dispose() {
    _cinemaController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    final cinema = _cinemaController.text.trim();
    final priceStr = _priceController.text.trim();

    if (cinema.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il nome del cinema')),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un prezzo valido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(financeProvider.notifier).addVisione(
        movieId: widget.movie.id,
        movieTitle: widget.movie.title,
        cinema: cinema,
        priceEur: price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.movie.title} registrato!')),
        );
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registra Visione'),
      backgroundColor: Colors.grey[900],
      contentTextStyle: const TextStyle(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Film: ${widget.movie.title}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cinemaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cinema',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _priceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Prezzo (€)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _onRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registra'),
        ),
      ],
    );
  }
}
