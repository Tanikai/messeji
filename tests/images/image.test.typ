#import "../../messeji.typ": messeji, get-image-names

#let mychat = json("image.test.json")

#let imagenames = get-image-names(mychat)
#repr(imagenames)


#let load-images(
  directory, // with trailing slash!
  image-names,
) = {
  for img-name in image-names.keys() {
    image-names.insert(
      img-name,
      image(
        directory + img-name,
        fit: "contain",
      ),
    )
  }
  return image-names
}

#let loaded-images = load-images("img/", imagenames)

#for (name, img) in loaded-images.pairs() {
  block(
    width: 50%,
    clip: true,
    fill: red,
    radius: 1em,
    img,
  )
}

#messeji(
  chat-data: mychat,
  images: loaded-images,
)

