
class Book {
    private String title;
}

class Library {
    // 仓库里的书，是从外部卡车运进来、通过参数传给图书馆的
    private List<Book> books;

    public Library(List<Book> marketBooks) {
        this.books = marketBooks;
    }
}

class LibraryController {
    public void search(Library lib) {
        // 临时借用 lib 对象查个东西
        System.out.println("正在检索图书馆...");
    }
}