//
//  ContentView.swift
//  Networking
//
//  Created by 神山賢太郎 on 2021/10/14.
//

import SwiftUI

//  Model
struct Photo: Codable, Identifiable {
    let id:String
    let author: String
    let width, height: Int
    let url, download_url: URL
}

struct PhotoLoadingError:Error {}

//  ViewModel
final class Remote<A>: ObservableObject {
    //  @Published: Modelに変更を通知。汎用化のためにジェネリックにしとる。
    @Published var result: Result<A, Error>? = nil
    //  try?: 例外を無視。なければnilを返却
    var value:A? { try? result?.get() }
    let url: URL
    //  APIからの結果をジェネリック型に変換する関数
    let transform: (Data) -> A?
    
    //  @escaping: クロージャが引数として関数に渡され、関数がリターンした後にそのクロージャが呼び出される場合に付与。init()後load関数を呼ぶため必要。
    init(url: URL, transform: @escaping (Data) -> A?) {
        self.url = url
        self.transform = transform
    }
    
    func load() {
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            DispatchQueue.main.async {
                if let d = data, let v = self.transform(d) {
                    self.result = .success(v)
                } else {
                    self.result = .failure(PhotoLoadingError())
                }
            }
        }.resume()
    }
}

//  画像をリンクから取得して表示するView
struct PhotoView: View {
    
    @ObservedObject var image: Remote<UIImage>
    
    init(_ url: URL) {
        self.image = Remote(url: url, transform: {UIImage(data: $0)})
    }
    
    var body: some View {
        Group {
            if image.value == nil {
                ProgressView()
                    .onAppear{image.load()}
            } else {
                Image(uiImage: image.value!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }.navigationTitle("Photo")
    }
}

struct ContentView: View {
    
    @ObservedObject var items = Remote(url: URL(string: "https://picsum.photos/v2/list")!, transform: {
        try? JSONDecoder().decode([Photo].self, from: $0)
    })
    
    var body: some View {
        NavigationView {
            if items.value == nil {
                ProgressView()
                    .onAppear {
                        items.load()
                    }
            } else {
                List {
                    ForEach(items.value!) { photo in
                        NavigationLink(
                            destination: PhotoView(photo.download_url),
                            label: {
                                Text(photo.author)
                            }
                        ).navigationTitle("Authors")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
