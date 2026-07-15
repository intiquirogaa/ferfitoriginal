import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/ferfit_mascot.dart';

class FeoStoreScreen extends StatefulWidget {
  const FeoStoreScreen({super.key});

  @override
  State<FeoStoreScreen> createState() => _FeoStoreScreenState();
}

class _FeoStoreScreenState extends State<FeoStoreScreen> {
  bool _isLoading = true;
  int _coins = 0;
  List<dynamic> _catalog = [];
  List<String> _ownedItems = [];
  String? _equippedSkin;


  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getInventory();
    if (data != null && mounted) {
      setState(() {
        _coins = data['coins'] ?? 0;
        _catalog = data['catalog'] ?? [];
        _ownedItems = List<String>.from(data['ownedItems'] ?? []);
        _equippedSkin = data['equippedSkin'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buyItem(String itemId, int price) async {
    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes FerCoins.')),
      );
      return;
    }
    
    // Optimistic update
    setState(() {
      _coins -= price;
      _ownedItems.add(itemId);
    });

    final res = await ApiService.buyItem(itemId);
    if (res != null) {
      _loadInventory(); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al comprar el ítem.')),
        );
      }
      _loadInventory(); // Revert optimistic update
    }
  }

  Future<void> _equipItem(String? itemId) async {
    setState(() {
      _equippedSkin = itemId;
    });
    final res = await ApiService.equipItem(itemId);
    if (res == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al equipar el ítem.')),
        );
      }
      _loadInventory(); // Revert optimistic update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSolid,
        title: const Text('La Tienda de Feo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                const SizedBox(height: 24),
                // Show mascot with equipped skin
                Center(
                  child: FerFitMascot(
                    size: 140,
                    anim: FeoAnim.wave,
                    equippedSkin: _equippedSkin,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _catalog.length,
                    itemBuilder: (context, index) {
                      final item = _catalog[index];
                      return _buildStoreItem(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStoreItem(Map<String, dynamic> item) {
    final String id = item['id'];
    final String name = item['name'];
    final String description = item['description'] ?? '';
    final int price = item['price'] ?? 0;
    final bool isOwned = _ownedItems.contains(id);
    final bool isEquipped = _equippedSkin == id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped ? AppColors.primary : AppColors.primary.withOpacity(0.2),
          width: isEquipped ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                _getEmojiForSkin(id),
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (!isOwned)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped
                    ? AppColors.cardSolid
                    : isOwned
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.8),
                foregroundColor: isEquipped ? AppColors.primary : Colors.black,
                side: isEquipped ? const BorderSide(color: AppColors.primary) : BorderSide.none,
              ),
              onPressed: () {
                if (isEquipped) {
                   _equipItem(null); 
                } else if (isOwned) {
                  _equipItem(id);
                } else {
                  _buyItem(id, price);
                }
              },
              child: Text(isEquipped ? 'Equipado' : isOwned ? 'Equipar' : 'Comprar'),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiForSkin(String id) {
    if (id == 'skin_headband') return '🥷'; 
    if (id == 'skin_sunglasses') return '😎';
    if (id == 'skin_cap') return '🧢';
    return '🎁';
  }

}
