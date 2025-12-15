package com.inventory;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Arrays;

@Repository
interface ProductRepository extends JpaRepository<Product, Long> {}

@RestController
@RequestMapping("/api/products")
public class ProductController {

    @Autowired
    private ProductRepository repository;

    @GetMapping
    public List<Product> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public Product create(@RequestBody Product product) {
        return repository.save(product);
    }

    @PostConstruct
    public void init() {
        if (repository.count() == 0) {
            Product p1 = new Product();
            p1.setName("Laptop");
            p1.setSku("TECH-001");
            p1.setCategory("Electronics");
            p1.setUnitPrice(1200.0);
            p1.setStockLevel(50);
            p1.setReorderLevel(10);
            
            Product p2 = new Product();
            p2.setName("Desk Chair");
            p2.setSku("FURN-002");
            p2.setCategory("Furniture");
            p2.setUnitPrice(150.0);
            p2.setStockLevel(5);
            p2.setReorderLevel(10);

            repository.saveAll(Arrays.asList(p1, p2));
        }
    }
}
